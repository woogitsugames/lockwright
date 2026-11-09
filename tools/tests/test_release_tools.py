"""tools/release (D-106): Android release preset generator and AAB gate helpers."""
import os
import struct
import subprocess
import sys
import types

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RELEASE = os.path.join(ROOT, "tools", "release")
sys.path.insert(0, RELEASE)

import check_aab  # noqa: E402

PRESETS = os.path.join(ROOT, "game", "export_presets.cfg")


def run_preset(tmp_path, *extra):
    cfg = tmp_path / "export_presets.cfg"
    cfg.write_text(open(PRESETS, encoding="utf-8").read(), encoding="utf-8")
    r = subprocess.run([sys.executable, os.path.join(RELEASE, "android_release_preset.py"), "--presets", str(cfg),
                        "--version-code", "10241", "--version-name", "0.1.0-ci.241", *extra],
                       capture_output=True, text=True)
    return r, cfg.read_text(encoding="utf-8")


def section(text, header):
    out, on = [], False
    for line in text.splitlines():
        if line.startswith("["):
            on = line.strip() == header
            continue
        if on:
            out.append(line)
    return out


def test_release_preset_copies_android_preset_and_never_reuses_an_index(tmp_path):
    r, text = run_preset(tmp_path, "--signed")
    assert r.returncode == 0, r.stderr
    idx = max(int(h[len("[preset."):-1]) for h in text.splitlines() if h.startswith("[preset.") and "options" not in h)
    head = section(text, "[preset.%d]" % idx)
    opts = section(text, "[preset.%d.options]" % idx)
    assert 'name="AndroidRelease"' in head
    # voice-pack presets stay intact (the old CI step appended a second [preset.3])
    assert text.count("[preset.3]") == 1 and 'name="Voice de"' in section(text, "[preset.3]")
    base = section(text, "[preset.0]")
    for key in ("include_filter=", "exclude_filter="):
        assert [l for l in head if l.startswith(key)] == [l for l in base if l.startswith(key)]
    for line in ("permissions/vibrate=true", "permissions/internet=true", "gradle_build/export_format=1",
                 "version/code=10241", 'version/name="0.1.0-ci.241"', "package/signed=true",
                 'keystore/release_password=""', "architectures/arm64-v8a=true", "architectures/armeabi-v7a=false"):
        assert line in opts, line


def test_release_preset_rejects_bad_versions(tmp_path):
    cfg = tmp_path / "p.cfg"
    cfg.write_text(open(PRESETS, encoding="utf-8").read(), encoding="utf-8")
    script = os.path.join(RELEASE, "android_release_preset.py")
    for code, name in (("0", "1.0"), ("2100000001", "1.0"), ("5", "voice packs")):
        r = subprocess.run([sys.executable, script, "--presets", str(cfg), "--version-code", code, "--version-name", name],
                           capture_output=True, text=True)
        assert r.returncode != 0


def elf(align):
    """Minimal 64-bit LE ELF header with one PT_LOAD program header."""
    hdr = bytearray(64)
    hdr[:4] = b"\x7fELF"
    hdr[4], hdr[5] = 2, 1
    struct.pack_into("<Q", hdr, 0x20, 64)          # e_phoff
    struct.pack_into("<HH", hdr, 0x36, 56, 1)      # e_phentsize, e_phnum
    ph = bytearray(56)
    struct.pack_into("<I", ph, 0, 1)               # PT_LOAD
    struct.pack_into("<Q", ph, 0x30, align)
    return bytes(hdr + ph)


def test_elf_alignment_reader():
    assert check_aab.elf_load_alignments(elf(16384)) == [16384]
    assert check_aab.elf_load_alignments(elf(4096)) == [4096]


MANIFEST = """<manifest xmlns:android="http://schemas.android.com/apk/res/android" android:versionCode="10241"
 android:versionName="0.1.0-ci.241" package="com.woogitsugames.lockwright">
 <uses-sdk android:minSdkVersion="30" android:targetSdkVersion="36"/>
 {perms}
 <application android:allowBackup="false" {app}/></manifest>"""


def manifest_errors(perms, app=""):
    xml = MANIFEST.format(perms="".join('<uses-permission android:name="%s"/>' % p for p in perms), app=app)
    args = types.SimpleNamespace(version_code=10241, version_name="0.1.0-ci.241")
    return check_aab.check_manifest(xml, args)[0]


def test_manifest_gate_permissions_and_debuggable():
    ok = ["android.permission.VIBRATE", "android.permission.INTERNET"]
    assert manifest_errors(ok) == []
    assert any("INTERNET" in e for e in manifest_errors(["android.permission.VIBRATE"]))
    assert any("ACCESS_NETWORK_STATE" in e for e in manifest_errors(ok + ["android.permission.ACCESS_NETWORK_STATE"]))
    assert any("debuggable" in e for e in manifest_errors(ok, 'android:debuggable="true"'))
    assert manifest_errors(ok + ["com.woogitsugames.lockwright.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION"]) == []
