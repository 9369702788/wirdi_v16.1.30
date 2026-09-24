from pathlib import Path

kts_path = Path('android/app/build.gradle.kts')
groovy_path = Path('android/app/build.gradle')
path = kts_path if kts_path.exists() else groovy_path
text = path.read_text()
is_kts = path.suffix == '.kts'

if 'isCoreLibraryDesugaringEnabled' not in text and 'coreLibraryDesugaringEnabled' not in text:
    flag = '        isCoreLibraryDesugaringEnabled = true\n' if is_kts else '        coreLibraryDesugaringEnabled true\n'
    text = text.replace('compileOptions {\n', 'compileOptions {\n' + flag, 1)

if 'coreLibraryDesugaring(' not in text and 'coreLibraryDesugaring ' not in text:
    dep = '    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n' if is_kts else "    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n"
    if '\ndependencies {' in text:
        text = text.replace('\ndependencies {', '\ndependencies {\n' + dep, 1)
    else:
        text += '\ndependencies {\n' + dep + '}\n'

path.write_text(text)
print('Gradle patched')


def find_block(haystack, anchor):
    idx = haystack.find(anchor)
    if idx == -1:
        return None
    brace_open = haystack.find('{', idx)
    if brace_open == -1:
        return None
    depth = 0
    i = brace_open
    while i < len(haystack):
        if haystack[i] == '{':
            depth += 1
        elif haystack[i] == '}':
            depth -= 1
            if depth == 0:
                return (brace_open, i + 1)
        i += 1
    return None


def patch_within_block(full_text, block_anchor, target, replacement):
    block = find_block(full_text, block_anchor)
    if block is None:
        return full_text, False
    start, end = block
    segment = full_text[start:end]
    if target not in segment:
        return full_text, False
    new_segment = segment.replace(target, replacement, 1)
    return full_text[:start] + new_segment + full_text[end:], True


def insert_into_block(full_text, block_anchor, insertion):
    block = find_block(full_text, block_anchor)
    if block is None:
        return full_text, False
    start, end = block
    insert_at = start + 1
    new_text = full_text[:insert_at] + '\n' + insertion + full_text[insert_at:]
    return new_text, True


def has_signing_configs_block(t):
    return 'signingConfigs {' in t

REPO_ROOT_REL = "../"

key_props_path = Path('key.properties')
if key_props_path.exists() and not has_signing_configs_block(text):
    if is_kts:
        text, wired = patch_within_block(
            text, 'buildTypes {',
            'getByName("release") {',
            'getByName("release") {\n            signingConfig = signingConfigs.getByName("release")',
        )
        if not wired:
            new_release_entry = (
                "        getByName(\"release\") {\n"
                "            signingConfig = signingConfigs.getByName(\"release\")\n"
                "        }\n"
            )
            text, wired = insert_into_block(text, 'buildTypes {', new_release_entry)
        signing_block = (
            "\nval keystoreProperties = java.util.Properties()\n"
            "val keystorePropertiesFile = rootProject.file(\"" + REPO_ROOT_REL + "key.properties\")\n"
            "if (keystorePropertiesFile.exists()) {\n"
            "    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))\n"
            "}\n"
        )
        text = text.replace('android {', signing_block + '\nandroid {', 1)
        signing_configs = (
            "    signingConfigs {\n"
            "        create(\"release\") {\n"
            "            keyAlias = keystoreProperties.getProperty(\"keyAlias\")\n"
            "            keyPassword = keystoreProperties.getProperty(\"keyPassword\")\n"
            "            storeFile = keystoreProperties.getProperty(\"storeFile\")?.let { rootProject.file(\"" + REPO_ROOT_REL + "$it\") }\n"
            "            storePassword = keystoreProperties.getProperty(\"storePassword\")\n"
            "        }\n"
            "    }\n"
        )
        text = text.replace('    buildTypes {', signing_configs + '    buildTypes {', 1)
    path.write_text(text)
    if wired:
        print('Release signingConfig wired up from key.properties')
    else:
        print('WARNING: could not find or insert getByName("release") inside buildTypes {} -- release signingConfigs block added, but NOT wired into the release buildType. Check the generated build.gradle.kts manually.')
elif not key_props_path.exists():
    print('No key.properties found -- release build will remain unsigned/debug-signed for now')
elif has_signing_configs_block(text):
    print('A signingConfigs {} block already exists -- not overwriting it (release path)')

# ---- ROOT CAUSE FIX (debug signing) ----
# v94: the real CI failure log (HARD GATE #2, apksigner mismatch)
# proved Flutter's current default-generated build.gradle.kts does NOT
# declare an explicit getByName("debug") {} entry inside buildTypes at
# all (it relies on AGP's implicit default debug buildType). v93 only
# tried to WIRE an existing debug entry and gave up with a warning when
# none existed -- meaning AGP fell back to guessing its own debug
# signing certificate again, the exact original bug this whole chain
# exists to eliminate. Now: if there is no existing debug entry to
# wire, INSERT a brand new one instead of giving up.
debug_keystore_path = Path('debug.keystore')
if debug_keystore_path.exists() and not has_signing_configs_block(text):
    if is_kts:
        text, wired = patch_within_block(
            text, 'buildTypes {',
            'getByName("debug") {',
            'getByName("debug") {\n            signingConfig = signingConfigs.getByName("debug")',
        )
        if not wired:
            new_debug_entry = (
                "        getByName(\"debug\") {\n"
                "            signingConfig = signingConfigs.getByName(\"debug\")\n"
                "        }\n"
            )
            text, wired = insert_into_block(text, 'buildTypes {', new_debug_entry)
        debug_signing_configs = (
            "    signingConfigs {\n"
            "        getByName(\"debug\") {\n"
            "            storeFile = rootProject.file(\"" + REPO_ROOT_REL + "debug.keystore\")\n"
            "            storePassword = \"android\"\n"
            "            keyAlias = \"androiddebugkey\"\n"
            "            keyPassword = \"android\"\n"
            "        }\n"
            "    }\n"
        )
        text = text.replace('    buildTypes {', debug_signing_configs + '    buildTypes {', 1)
    else:
        debug_signing_configs = (
            "    signingConfigs {\n"
            "        debug {\n"
            "            storeFile rootProject.file('" + REPO_ROOT_REL + "debug.keystore')\n"
            "            storePassword 'android'\n"
            "            keyAlias 'androiddebugkey'\n"
            "            keyPassword 'android'\n"
            "        }\n"
            "    }\n"
        )
        text = text.replace('    buildTypes {', debug_signing_configs + '    buildTypes {', 1)
        wired = True
    path.write_text(text)
    if wired:
        print('Explicit debug signingConfig wired up (existing entry patched or new one inserted) -- Gradle will now deterministically use the committed debug.keystore instead of guessing its location')
    else:
        print('WARNING: could not wire or insert a debug buildType entry inside buildTypes {}. AGP will fall back to its own default debug signing for this build; check the generated build.gradle.kts manually.')
elif has_signing_configs_block(text):
    print('A signingConfigs {} block already exists (release path just added it, or one pre-existed) -- debug entry must be added manually inside it if not already covered')
else:
    print('WARNING: debug.keystore not found at repo root -- explicit debug signingConfig NOT added')

# ---- PRODUCTION READINESS: pin compileSdk/targetSdk explicitly ----
# CI installs Flutter via `channel: stable` with NO specific version
# pinned -- different stable Flutter releases bundle different default
# compileSdkVersion/targetSdkVersion values in their generated
# build.gradle(.kts) template (they reference flutter.compileSdkVersion
# / flutter.targetSdkVersion, computed internally by whichever Flutter
# tool version happens to be installed that day). That means "what API
# level this app actually targets" was previously NOT deterministic
# across builds -- exactly the kind of silent drift Google Play's
# target-API-level requirement (API 36 for 2026) cannot tolerate.
# Force explicit, deterministic values regardless of Flutter version.
text2 = path.read_text()
if is_kts:
    text2 = text2.replace('compileSdk = flutter.compileSdkVersion', 'compileSdk = 36')
    text2 = text2.replace('targetSdk = flutter.targetSdkVersion', 'targetSdk = 36')
else:
    text2 = text2.replace('compileSdk flutter.compileSdkVersion', 'compileSdk 36')
    text2 = text2.replace('targetSdk flutter.targetSdkVersion', 'targetSdk 36')
if text2 != path.read_text():
    path.write_text(text2)
    print('compileSdk/targetSdk pinned to 36 (was flutter.compileSdkVersion/targetSdkVersion)')
else:
    print('WARNING: could not find the expected flutter.compileSdkVersion/targetSdkVersion lines to pin -- '
          'the generated build.gradle(.kts) may use different property names than expected. '
          'Check android/app/build.gradle(.kts) manually and verify compileSdk/targetSdk are 36.')


# ---- FIX v219: force ALL Android modules (including third-party plugins
# like file_picker) to compile against the same SDK version as our app.
# ROOT CAUSE (2026-09 CI failure #1): Flutter plugin subprojects (fetched
# from pub, NOT part of this repo, e.g. file_picker) set their OWN
# compileSdk via `flutter.compileSdkVersion`, resolved from whichever
# Flutter SDK release the CI runner has installed that day (channel:
# stable, unpinned). Pinning ONLY android/app/build.gradle(.kts) (done
# above) has ZERO effect on plugin subprojects -- each is its own
# independent Gradle module. Build failed with:
# ":file_picker is currently compiled against android-34" while a
# transitive dependency (flutter_plugin_android_lifecycle) required 36+.
#
# ROOT CAUSE (2026-09 CI failure #2, v218 attempt): the first fix for
# this used `subprojects {{ afterEvaluate {{ ... }} }}` APPENDED at the
# END of android/build.gradle.kts -- i.e. registered AFTER the
# Flutter-template's own `subprojects {{ project.evaluationDependsOn(":app") }}`
# block. `evaluationDependsOn(":app")` forces Gradle to fully evaluate
# the :app project immediately, INCLUDING running every subprojects{{}}
# action registered on it SO FAR -- by the time our afterEvaluate action
# (registered LAST) was reached, :app had often already finished
# evaluating, and calling `Project.afterEvaluate()` on an
# already-evaluated project throws:
# "Cannot run Project.afterEvaluate(Action) when the project is already
# evaluated." Fix: register our override as the FIRST subprojects{{}}
# action in the file (inserted before the Flutter template's own
# subprojects{{}} blocks), so our afterEvaluate callback is attached to
# every project BEFORE evaluationDependsOn can force early evaluation.
root_kts_path = Path('android/build.gradle.kts')
root_groovy_path = Path('android/build.gradle')
root_path = root_kts_path if root_kts_path.exists() else root_groovy_path

if root_path.exists():
    root_text = root_path.read_text()
    if 'FORCE_COMPILE_SDK_ALL_SUBPROJECTS' not in root_text:
        if root_path.suffix == '.kts':
            override_block = (
                '// FORCE_COMPILE_SDK_ALL_SUBPROJECTS -- see patch_gradle.py for why this exists\n'
                'subprojects {\n'
                '    afterEvaluate {\n'
                '        val androidExt = extensions.findByName("android")\n'
                '        if (androidExt is com.android.build.gradle.BaseExtension) {\n'
                '            androidExt.compileSdkVersion(36)\n'
                '        }\n'
                '    }\n'
                '}\n\n'
            )
        else:
            override_block = (
                '// FORCE_COMPILE_SDK_ALL_SUBPROJECTS -- see patch_gradle.py for why this exists\n'
                'subprojects {\n'
                '    afterEvaluate { proj ->\n'
                '        if (proj.hasProperty("android")) {\n'
                '            proj.android {\n'
                '                compileSdkVersion 36\n'
                '            }\n'
                '        }\n'
                '    }\n'
                '}\n\n'
            )

        # Insert BEFORE the first existing "subprojects {" / "subprojects{"
        # declaration, so our afterEvaluate registers before any
        # evaluationDependsOn() call can force early evaluation. If no
        # subprojects block exists at all (unexpected), fall back to
        # inserting right after the first "allprojects" block, or else
        # prepend at the very top of the file.
        insert_idx = root_text.find('subprojects {')
        if insert_idx == -1:
            insert_idx = root_text.find('subprojects{')
        if insert_idx == -1:
            # Fallback: put it at the very top of the file (still valid
            # Gradle -- subprojects{} can appear anywhere at top level).
            new_root_text = override_block + root_text
            print('WARNING: no existing "subprojects {" found -- prepended override at top of file instead')
        else:
            new_root_text = root_text[:insert_idx] + override_block + root_text[insert_idx:]
        root_path.write_text(new_root_text)
        print(f'Forced compileSdk=36 for ALL subprojects (plugins included) via {root_path}, inserted BEFORE the first existing subprojects{{}} block to avoid the already-evaluated error')
    else:
        print(f'Subprojects compileSdk override already present in {root_path} -- skipping')
else:
    print('WARNING: neither android/build.gradle.kts nor android/build.gradle found -- '
          'could not add the subprojects-wide compileSdk override. Third-party plugins '
          'may still fail to build against a newer required SDK level.')
