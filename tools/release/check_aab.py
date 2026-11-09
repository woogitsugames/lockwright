#!/usr/bin/env python3
"""Release AAB gate for Google Play (D-106). Fails (exit 1) when the bundle would be rejected by Play
or ships something we did not decide to ship.

Checks
  - manifest (via `bundletool dump manifest`): package, versionCode/versionName (when expected values
    are given), minSdk/targetSdk, no android:debuggable="true", permissions == allowlist
  - native code: only lib/arm64-v8a/ (64-bit only, D-10) and every .so has 16 KB-aligned LOAD
    segments (Play requirement for apps targeting Android 15+ since 2025-11-01)
  - signing (with --require-signed): the bundle carries a JAR signature (upload key)

   python3 tools/release/check_aab.py --aab game/build/lockwright-release.aab --bundletool bundletool.jar \
       [--java java] [--version-code 10123] [--version-name 0.1.0-ci.123] [--require-signed] [--summary out.md]
"""
import argparse, re, struct, subprocess, sys, zipfile
import xml.etree.ElementTree as ET

PACKAGE = "com.woogitsugames.lockwright"
MIN_SDK = 30          # D-10
TARGET_SDK_MIN = 35   # Play: new apps and updates must target API 35+ (2025-08-31); we build with 36
# Every permission must be justified in docs/handoff/PLAY-DATA-SAFETY.md §2 before it is added here.
ALLOWED_PERMISSIONS = {
    "android.permission.VIBRATE",   # haptics (N-55), normal permission, no data
    "android.permission.INTERNET",  # on-demand voice packs only (D-62/D-63/D-100)
}
# Signature-level permission AndroidX may declare for the app itself; not a user-facing permission.
OWN_PERMISSION_SUFFIX = ".DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION"
PAGE_16K = 16384
ANDROID_NS = "{http://schemas.android.com/apk/res/android}"


def elf_load_alignments(data):
    """p_align of every PT_LOAD segment of a 64-bit little-endian ELF."""
    if data[:4] != b"\x7fELF":
        raise ValueError("not an ELF file")
    if data[4] != 2 or data[5] != 1:
        raise ValueError("not a 64-bit little-endian ELF")
    e_phoff, = struct.unpack_from("<Q", data, 0x20)
    e_phentsize, e_phnum = struct.unpack_from("<HH", data, 0x36)
    out = []
    for i in range(e_phnum):
        off = e_phoff + i * e_phentsize
        p_type, = struct.unpack_from("<I", data, off)
        if p_type == 1:  # PT_LOAD
            p_align, = struct.unpack_from("<Q", data, off + 0x30)
            out.append(p_align)
    return out


def check_native(zf):
    errors, rows = [], []
    for name in zf.namelist():
        if not name.endswith(".so"):
            continue
        m = re.match(r"^base/lib/([^/]+)/", name)
        abi = m.group(1) if m else "?"
        if abi != "arm64-v8a":
            errors.append("native library outside arm64-v8a: %s" % name)
            continue
        aligns = elf_load_alignments(zf.read(name))
        low = [a for a in aligns if a < PAGE_16K]
        rows.append((name, min(aligns) if aligns else 0))
        if low:
            errors.append("%s: LOAD segment alignment %d < 16 KB (rebuild with NDK r28+ or -Wl,-z,max-page-size=16384)"
                          % (name, min(low)))
    if not rows:
        errors.append("no native libraries in base/lib/arm64-v8a (broken export?)")
    return errors, rows


def check_manifest(xml_text, args):
    errors, facts = [], {}
    root = ET.fromstring(xml_text)
    a = lambda el, k: el.get(ANDROID_NS + k)
    facts["package"] = root.get("package")
    facts["versionCode"] = a(root, "versionCode")
    facts["versionName"] = a(root, "versionName")
    if facts["package"] != PACKAGE:
        errors.append("package %s != %s" % (facts["package"], PACKAGE))
    if args.version_code is not None and facts["versionCode"] != str(args.version_code):
        errors.append("versionCode %s != expected %s" % (facts["versionCode"], args.version_code))
    if args.version_name is not None and facts["versionName"] != args.version_name:
        errors.append("versionName %s != expected %s" % (facts["versionName"], args.version_name))
    sdk = root.find("uses-sdk")
    mn = int(a(sdk, "minSdkVersion") or 0) if sdk is not None else 0
    tg = int(a(sdk, "targetSdkVersion") or 0) if sdk is not None else 0
    facts["minSdk"], facts["targetSdk"] = mn, tg
    if mn < MIN_SDK:
        errors.append("minSdkVersion %d < %d (D-10)" % (mn, MIN_SDK))
    if tg < TARGET_SDK_MIN:
        errors.append("targetSdkVersion %d < %d (Google Play target API requirement)" % (tg, TARGET_SDK_MIN))
    app = root.find("application")
    if app is None:
        errors.append("no <application> in manifest")
    else:
        if (a(app, "debuggable") or "").lower() == "true":
            errors.append('android:debuggable="true" in a release bundle')
        facts["allowBackup"] = a(app, "allowBackup")
        facts["debuggable"] = a(app, "debuggable") or "absent"
    perms = sorted({a(p, "name") for p in root.iter("uses-permission")} |
                   {a(p, "name") for p in root.iter("uses-permission-sdk-23")})
    facts["permissions"] = perms
    for p in perms:
        if p in ALLOWED_PERMISSIONS or (p.startswith(PACKAGE) and p.endswith(OWN_PERMISSION_SUFFIX)):
            continue
        errors.append("permission not on the allowlist: %s (justify it in docs/handoff/PLAY-DATA-SAFETY.md first)" % p)
    for p in sorted(ALLOWED_PERMISSIONS - set(perms)):
        errors.append("expected permission missing: %s" % p)
    return errors, facts


def is_signed(zf):
    return any(re.match(r"^META-INF/[^/]+\.(RSA|DSA|EC)$", n) for n in zf.namelist())


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--aab", required=True)
    ap.add_argument("--bundletool", required=True, help="path to bundletool-all-<ver>.jar")
    ap.add_argument("--java", default="java")
    ap.add_argument("--version-code", type=int)
    ap.add_argument("--version-name")
    ap.add_argument("--require-signed", action="store_true")
    ap.add_argument("--summary", help="append a markdown table here (e.g. $GITHUB_STEP_SUMMARY)")
    args = ap.parse_args()

    xml_text = subprocess.run([args.java, "-jar", args.bundletool, "dump", "manifest", "--bundle", args.aab],
                              check=True, capture_output=True, text=True).stdout
    errors, facts = check_manifest(xml_text, args)
    with zipfile.ZipFile(args.aab) as zf:
        nerr, rows = check_native(zf)
        signed = is_signed(zf)
    errors += nerr
    facts["signed"] = signed
    if args.require_signed and not signed:
        errors.append("bundle is not signed (upload key missing)")

    lines = ["## Release AAB gate (D-106)", "", "| Field | Value |", "|---|---|"]
    for k in ("package", "versionCode", "versionName", "minSdk", "targetSdk", "debuggable", "allowBackup", "signed"):
        lines.append("| %s | `%s` |" % (k, facts.get(k)))
    lines.append("| permissions | %s |" % ", ".join("`%s`" % p for p in facts["permissions"]))
    for name, al in rows:
        lines.append("| %s | min LOAD align %d |" % (name, al))
    lines.append("")
    lines += ["**FAIL:** " + e for e in errors] or ["**OK**"]
    text = "\n".join(lines) + "\n"
    print(text)
    if args.summary:
        with open(args.summary, "a", encoding="utf-8") as f:
            f.write(text)
    for e in errors:
        print("::error::%s" % e)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
