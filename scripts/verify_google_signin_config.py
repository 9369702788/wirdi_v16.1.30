#!/usr/bin/env python3
"""
VERIFIED FACT ABOUT google-services.json's SCHEMA: each Android OAuth
client's "android_info" block has ONLY "package_name" and
"certificate_hash" (a SHA-1). There is NO SHA-256 field in this file --
confirmed by inspecting the real file, not assumed. Google Sign-In /
OAuth client matching at this layer is SHA-1 only.

SHA-256 matters for OTHER features (Digital Asset Links / App Links,
Play Integrity, some Credential Manager flows), configured separately
in Firebase Console / Play Console -- NOT inside google-services.json.
--keystore-sha256 is captured and printed for the CI log / audit trail
only; it is NOT compared against anything because there is nothing in
this file to compare it to.
"""
import argparse
import json
import re
import sys


def normalize_hash(s):
    return s.replace(":", "").replace("-", "").strip().lower()


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--google-services", default="google-services.json")
    p.add_argument("--auth-service", default="lib/core/services/auth_service.dart")
    p.add_argument("--package", default="com.wirdi.wirdi")
    p.add_argument("--firebase-project", default="wirdi-cb813")
    p.add_argument("--keystore-sha1", default=None, help="SHA-1 of the keystore that actually signed THIS build")
    p.add_argument("--keystore-sha256", default=None, help="SHA-256 of the same keystore (informational, see docstring)")
    p.add_argument("--build-type", default="unknown", choices=["debug", "release", "play-app-signing", "unknown"],
                    help="debug/release/play-app-signing keystores are commonly DIFFERENT certificates")
    p.add_argument("--firebase-options", default="lib/firebase_options.dart",
                    help="Dart file passed to Firebase.initializeApp(options: ...) -- must describe the SAME project as google-services.json")
    args = p.parse_args()
    report = []

    try:
        with open(args.google_services, encoding="utf-8") as f:
            gs = json.load(f)
    except FileNotFoundError:
        report.append(("FAIL", args.google_services + " not found"))
        sys.exit(finish(report, args))
    except json.JSONDecodeError as e:
        report.append(("FAIL", args.google_services + " invalid JSON: " + str(e)))
        sys.exit(finish(report, args))
    report.append(("PASS", args.google_services + " found and parses"))

    packages = [c.get("client_info", {}).get("android_client_info", {}).get("package_name") for c in gs.get("client", [])]
    if args.package in packages:
        report.append(("PASS", "Package '" + args.package + "' present"))
    else:
        report.append(("FAIL", "Package '" + args.package + "' NOT found (found: " + str(packages) + ")"))

    project_id = gs.get("project_info", {}).get("project_id")
    if project_id == args.firebase_project:
        report.append(("PASS", "Firebase project matches ('" + str(project_id) + "')"))
    else:
        report.append(("FAIL", "Firebase project mismatch: expected '" + args.firebase_project + "', found '" + str(project_id) + "'"))

    try:
        with open(args.auth_service, encoding="utf-8") as f:
            auth_src = f.read()
    except FileNotFoundError:
        auth_src = ""
        report.append(("FAIL", args.auth_service + " not found"))

    # FIXED in v85: previously double-escaped when the file was generated
    # (each backslash became two), so it searched for a literal backslash
    # character in the Dart source instead of whitespace/word-char classes
    # -- it could never match real code. Verified against the ACTUAL
    # auth_service.dart content before shipping this fix.
    m = re.search(r"serverClientId:\s*'([\w.\-]+\.apps\.googleusercontent\.com)'", auth_src)
    web_clients = set(oc.get("client_id") for c in gs.get("client", []) for oc in c.get("oauth_client", []) if oc.get("client_type") == 3)
    if not m:
        report.append(("FAIL", "No serverClientId in " + args.auth_service))
    elif m.group(1) in web_clients:
        report.append(("PASS", "serverClientId matches a real Web OAuth client (type 3)"))
    else:
        report.append(("FAIL", "serverClientId '" + m.group(1) + "' not in google-services.json (found: " + str(web_clients) + ")"))

    android_hashes = set(normalize_hash(oc["android_info"]["certificate_hash"]) for c in gs.get("client", []) for oc in c.get("oauth_client", []) if oc.get("client_type") == 1 and "android_info" in oc)
    if android_hashes:
        report.append(("PASS", str(len(android_hashes)) + " Android OAuth client(s) (SHA-1) registered"))
    else:
        report.append(("FAIL", "No Android OAuth clients found"))

    malformed = [oc for c in gs.get("client", []) for oc in c.get("oauth_client", []) if oc.get("client_type") == 1 and "android_info" not in oc]
    if malformed:
        report.append(("FAIL", str(len(malformed)) + " malformed Android OAuth client(s)"))
    else:
        report.append(("PASS", "No malformed Android OAuth client entries"))

    try:
        with open(args.firebase_options, encoding="utf-8") as f:
            fo_src = f.read()
    except FileNotFoundError:
        fo_src = None
        report.append(("FAIL", args.firebase_options + " not found -- cannot verify it matches google-services.json"))

    if fo_src is not None:
        android_block_match = re.search(r"static const FirebaseOptions android = FirebaseOptions\((.*?)\);", fo_src, re.DOTALL)
        if not android_block_match:
            report.append(("FAIL", "Could not find FirebaseOptions android block in " + args.firebase_options))
        else:
            block = android_block_match.group(1)

            def _field(name):
                m = re.search(name + r":\s*'([^']*)'", block)
                return m.group(1) if m else None

            fo_project_id = _field("projectId")
            fo_sender_id = _field("messagingSenderId")
            fo_app_id = _field("appId")

            gs_project_id = gs.get("project_info", {}).get("project_id")
            gs_project_number = gs.get("project_info", {}).get("project_number")
            gs_app_ids = [c.get("client_info", {}).get("mobilesdk_app_id") for c in gs.get("client", [])]

            if fo_project_id == gs_project_id:
                report.append(("PASS", "firebase_options.dart projectId matches google-services.json ('" + str(fo_project_id) + "')"))
            else:
                report.append(("FAIL", "firebase_options.dart projectId ('" + str(fo_project_id) + "') != google-services.json project_id ('" + str(gs_project_id) + "')"))

            if fo_sender_id == gs_project_number:
                report.append(("PASS", "firebase_options.dart messagingSenderId matches google-services.json project_number"))
            else:
                report.append(("FAIL", "firebase_options.dart messagingSenderId ('" + str(fo_sender_id) + "') != google-services.json project_number ('" + str(gs_project_number) + "')"))

            if fo_app_id in gs_app_ids:
                report.append(("PASS", "firebase_options.dart appId matches a google-services.json client app id"))
            else:
                report.append(("FAIL", "firebase_options.dart appId ('" + str(fo_app_id) + "') not found in google-services.json"))

    build_label = args.build_type.upper()
    if args.keystore_sha1:
        target = normalize_hash(args.keystore_sha1)
        if target in android_hashes:
            report.append(("PASS", "[" + build_label + "] Signing SHA-1 (" + args.keystore_sha1 + ") MATCHES a registered Android OAuth client"))
        else:
            report.append(("FAIL", "[" + build_label + "] Signing SHA-1 (" + args.keystore_sha1 + ") does NOT match any registered client -- Google Sign-In WILL FAIL for this exact build"))
    else:
        report.append(("SKIP", "No --keystore-sha1 given -- did not verify this build's actual certificate"))

    if args.keystore_sha256:
        report.append(("INFO", "[" + build_label + "] Signing SHA-256 (" + args.keystore_sha256 + ") -- NOT checked against google-services.json (no SHA-256 field exists there). Logged for App Links / Play Integrity / audit trail."))
    else:
        report.append(("SKIP", "No --keystore-sha256 given"))

    sys.exit(finish(report, args))


def finish(report, args):
    print("Google Sign-In Configuration (" + args.build_type.upper() + " build)")
    print("----------------------------")
    all_pass = True
    for status, msg in report:
        print(status + ": " + msg)
        if status == "FAIL":
            all_pass = False
    print("----------------------------")
    verdict = "VALID (file/certificate consistency only)" if all_pass else "INVALID"
    print("GOOGLE SIGN-IN CONFIGURATION: " + verdict)
    if all_pass:
        print("NOTE: this does NOT prove Google Sign-In works at runtime. It proves the")
        print("config files and THIS build's signing certificate are internally consistent.")
        print("The only real proof is installing this exact APK on a device and testing Sign-In.")
    return 0 if all_pass else 1


if __name__ == "__main__":
    main()
