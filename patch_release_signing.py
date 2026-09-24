"""
Wirdi -- wire the REAL release signing config into android/app/build.gradle.kts.

WHY THIS EXISTS
  Flutter 3.35's generated build.gradle.kts contains:
      release { signingConfig = signingConfigs.getByName("debug") }
  patch_gradle.py runs BEFORE key.properties is created in CI, and its
  release branch looks for `getByName("release") {` which the template
  never contains -- so the release build type stays signed with the DEBUG
  key. Google Play rejects that, and HARD GATE #3 correctly fails.

WHEN TO RUN
  In build_apk.yml, AFTER the step that writes key.properties and
  release.keystore and BEFORE `flutter build appbundle --release`.
  Safe to run when key.properties is missing (it does nothing).
  Idempotent.
"""
import re
import sys
from pathlib import Path

KTS = Path("android/app/build.gradle.kts")
KEYPROPS = Path("key.properties")

if not KEYPROPS.exists():
    print("key.properties not found -- release signing NOT wired (expected when secrets are absent).")
    sys.exit(0)
if not KTS.exists():
    print("ERROR: android/app/build.gradle.kts not found")
    sys.exit(1)

text = KTS.read_text()

if 'signingConfigs.getByName("release")' in text and 'create("release")' in text:
    print("Release signing already wired -- nothing to do.")
    sys.exit(0)


def block_span(src, anchor_regex, start=0):
    """Return (open_brace_idx, close_brace_idx_exclusive) of the first block
    whose header matches anchor_regex, using brace counting."""
    m = re.compile(anchor_regex).search(src, start)
    if not m:
        return None
    open_idx = src.find("{", m.start())
    depth, i = 0, open_idx
    while i < len(src):
        if src[i] == "{":
            depth += 1
        elif src[i] == "}":
            depth -= 1
            if depth == 0:
                return (open_idx, i + 1)
        i += 1
    return None


# 1) load key.properties (repo root = one level above android/)
if "keystoreProperties" not in text:
    loader = (
        "\nval keystoreProperties = java.util.Properties()\n"
        'val keystorePropertiesFile = rootProject.file("../key.properties")\n'
        "if (keystorePropertiesFile.exists()) {\n"
        "    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))\n"
        "}\n"
    )
    idx = text.find("\nandroid {")
    if idx == -1:
        print("ERROR: could not find `android {` block")
        sys.exit(1)
    text = text[:idx] + loader + text[idx:]

# 2) add create("release") inside the existing signingConfigs block (or make one)
release_cfg = (
    '        create("release") {\n'
    '            keyAlias = keystoreProperties.getProperty("keyAlias")\n'
    '            keyPassword = keystoreProperties.getProperty("keyPassword")\n'
    '            storeFile = keystoreProperties.getProperty("storeFile")?.let { rootProject.file("../$it") }\n'
    '            storePassword = keystoreProperties.getProperty("storePassword")\n'
    "        }\n"
)
sc = block_span(text, r"signingConfigs\s*\{")
if sc:
    text = text[: sc[0] + 1] + "\n" + release_cfg + text[sc[0] + 1 :]
else:
    bt = re.search(r"\n\s*buildTypes\s*\{", text)
    if not bt:
        print("ERROR: could not find `buildTypes {` block")
        sys.exit(1)
    text = text[: bt.start()] + "\n    signingConfigs {\n" + release_cfg + "    }\n" + text[bt.start() :]

# 3) point the release build type at it (replace debug signing INSIDE release {...} only)
bt_span = block_span(text, r"buildTypes\s*\{")
if not bt_span:
    print("ERROR: buildTypes block vanished")
    sys.exit(1)
bt_body = text[bt_span[0] : bt_span[1]]
rel = block_span(bt_body, r"(?<![A-Za-z])release\s*\{|getByName\(\"release\"\)\s*\{")
if rel:
    seg = bt_body[rel[0] : rel[1]]
    new_seg, n = re.subn(
        r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)',
        'signingConfig = signingConfigs.getByName("release")',
        seg,
    )
    if n == 0 and 'signingConfigs.getByName("release")' not in seg:
        new_seg = seg[:1] + '\n            signingConfig = signingConfigs.getByName("release")' + seg[1:]
    bt_body = bt_body[: rel[0]] + new_seg + bt_body[rel[1] :]
else:
    bt_body = bt_body[:1] + '\n        release {\n            signingConfig = signingConfigs.getByName("release")\n        }\n' + bt_body[1:]
text = text[: bt_span[0]] + bt_body + text[bt_span[1] :]

KTS.write_text(text)

# 4) hard self-check: refuse to continue if the release block still uses debug signing
final = KTS.read_text()
b = block_span(final, r"buildTypes\s*\{")
body = final[b[0] : b[1]]
r = block_span(body, r"(?<![A-Za-z])release\s*\{|getByName\(\"release\"\)\s*\{")
release_body = body[r[0] : r[1]] if r else ""
if 'getByName("release")' not in release_body or 'getByName("debug")' in release_body:
    print("ERROR: release buildType is NOT using the release signingConfig after patching:")
    print(release_body)
    sys.exit(1)
print("Release signingConfig wired: release buildType now signs with key.properties/release.keystore.")
