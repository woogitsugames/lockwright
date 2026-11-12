"""tools/build_content_packs.py (D-112): pack source validation and the data-only gate."""
import hashlib
import json
import os

import build_content_packs as cp

PID = "ch77"


def make_pack(tmp_path, jobs=("job.demo_one",), chapter=77, with_import=True):
    """A minimal valid pack source folder; returns (pack_dir, base_jobs_dir, base_csv_list)."""
    pack = tmp_path / "packs" / PID
    (pack / "jobs").mkdir(parents=True)
    (pack / "i18n").mkdir()
    (pack / "arrival" / "demo" / "evening").mkdir(parents=True)
    rows = ["keys,en,pl,de,fr,es"]
    for jid in jobs:
        (pack / "jobs" / (jid + ".json")).write_text(json.dumps(
            {"id": jid, "chapter": chapter, "family": "wafer", "tier": 2, "i18n": {"title": jid + ".title"}}),
            encoding="utf-8")
        rows.append("%s.title,A,B,C,D,E" % jid)
    (pack / "i18n" / "content.csv").write_text("\n".join(rows) + "\n", encoding="utf-8")
    (pack / "arrival" / "demo" / "evening" / "plate.webp").write_bytes(b"RIFF")
    if with_import:
        (pack / "i18n" / "content.csv.import").write_text("[params]\n\ncompress=0\n", encoding="utf-8")
        (pack / "arrival" / "demo" / "evening" / "plate.webp.import").write_text("[remap]\n", encoding="utf-8")
    (pack / "arrival_scenes.json").write_text(json.dumps(
        {"scenes": {jobs[0]: {"dir": "res://packs/%s/arrival/demo" % PID, "times": ["evening"]}}}), encoding="utf-8")
    (pack / "pack.json").write_text(json.dumps(
        {"schema": cp.PACK_SCHEMA, "id": PID, "version": 1, "min_game": 1, "chapters": [chapter]}), encoding="utf-8")
    base_jobs = tmp_path / "base_jobs"
    base_jobs.mkdir()
    base_csv = tmp_path / "base.csv"
    base_csv.write_text("keys,en,pl,de,fr,es\njobs.title,Jobs,Zlecenia,Aufträge,Interventions,Encargos\n", encoding="utf-8")
    cp.sync_jobs(str(pack))
    return pack, str(base_jobs), [str(base_csv)]


def check(pack, base_jobs, base_csv):
    return cp.check_source(PID, str(pack), base_jobs, base_csv)


def test_valid_pack_passes_and_sync_writes_jobs(tmp_path):
    pack, base_jobs, base_csv = make_pack(tmp_path, jobs=("job.demo_one", "job.demo_two"))
    assert check(pack, base_jobs, base_csv) == []
    data = json.loads((pack / "pack.json").read_text(encoding="utf-8"))
    assert data["jobs"] == {"job.demo_one": {"chapter": 77, "family": "wafer", "tier": 2},
                            "job.demo_two": {"chapter": 77, "family": "wafer", "tier": 2}}
    assert cp.sync_jobs(str(pack)) is False  # already in step


def test_jobs_list_out_of_step_is_an_error(tmp_path):
    pack, base_jobs, base_csv = make_pack(tmp_path)
    (pack / "jobs" / "job.demo_new.json").write_text(json.dumps(
        {"id": "job.demo_new", "chapter": 77, "family": "lever", "i18n": {}}), encoding="utf-8")
    assert any("--sync" in e for e in check(pack, base_jobs, base_csv))


def test_job_rules(tmp_path):
    pack, base_jobs, base_csv = make_pack(tmp_path)
    # the same job still in the base game
    open(os.path.join(base_jobs, "job.demo_one.json"), "w").write("{}")
    assert any("base game already has this job" in e for e in check(pack, base_jobs, base_csv))
    os.remove(os.path.join(base_jobs, "job.demo_one.json"))
    # a job of a chapter the pack does not declare
    (pack / "jobs" / "job.demo_one.json").write_text(json.dumps(
        {"id": "job.demo_one", "chapter": 5, "family": "wafer", "i18n": {}}), encoding="utf-8")
    cp.sync_jobs(str(pack))
    assert any("chapter 5 is not one of the pack's" in e for e in check(pack, base_jobs, base_csv))
    # a file not named after its id
    (pack / "jobs" / "other.json").write_text(json.dumps({"id": "job.demo_x", "chapter": 77}), encoding="utf-8")
    assert any("named after its id" in e for e in check(pack, base_jobs, base_csv))


def test_texts_rules(tmp_path):
    pack, base_jobs, base_csv = make_pack(tmp_path)
    csv_path = pack / "i18n" / "content.csv"
    # a key the base game already has
    csv_path.write_text(csv_path.read_text(encoding="utf-8") + "jobs.title,a,b,c,d,e\n", encoding="utf-8")
    assert any("already in the base game" in e for e in check(pack, base_jobs, base_csv))
    # a job text that is nowhere
    csv_path.write_text("keys,en,pl,de,fr,es\n", encoding="utf-8")
    assert any("is in no content.csv" in e for e in check(pack, base_jobs, base_csv))
    # four languages only
    csv_path.write_text("keys,en,pl,de,fr\njob.demo_one.title,A,B,C,D\n", encoding="utf-8")
    assert any("header must be" in e for e in check(pack, base_jobs, base_csv))


def test_csv_import_must_be_uncompressed_and_sync_fixes_it(tmp_path):
    pack, base_jobs, base_csv = make_pack(tmp_path)
    imp = pack / "i18n" / "content.csv.import"
    imp.write_text("[params]\n\ncompress=1\ndelimiter=0\n", encoding="utf-8")
    assert any("compress must be 0" in e for e in check(pack, base_jobs, base_csv))
    assert cp.sync_jobs(str(pack)) is True
    assert "compress=0" in imp.read_text(encoding="utf-8")
    assert check(pack, base_jobs, base_csv) == []


def test_only_data_files_and_imports(tmp_path):
    pack, base_jobs, base_csv = make_pack(tmp_path, with_import=False)
    errors = check(pack, base_jobs, base_csv)
    assert any("missing plate.webp.import" in e for e in errors)
    assert any("missing content.csv.import" in e for e in errors)
    pack2, base_jobs2, base_csv2 = make_pack(tmp_path / "second")
    (pack2 / "patch.gd").write_text("extends Node\n", encoding="utf-8")
    (pack2 / "scene.tscn").write_text("[gd_scene]\n", encoding="utf-8")
    errors = check(pack2, base_jobs2, base_csv2)
    assert any(e.startswith("patch.gd: only data files") for e in errors)
    assert any(e.startswith("scene.tscn: only data files") for e in errors)


def test_arrival_scene_rules(tmp_path):
    pack, base_jobs, base_csv = make_pack(tmp_path)
    scenes = pack / "arrival_scenes.json"
    scenes.write_text(json.dumps({"scenes": {
        "job.demo_one": {"dir": "res://assets/arrival/cat_bathroom"},
        "job.someone_else": {"dir": "res://packs/%s/arrival/demo" % PID}}}), encoding="utf-8")
    errors = check(pack, base_jobs, base_csv)
    assert any("dir must be under res://packs/%s/" % PID in e for e in errors)
    assert any("job.someone_else is not a job of this pack" in e for e in errors)


def test_pack_json_rules(tmp_path):
    pack, base_jobs, base_csv = make_pack(tmp_path)
    good = json.loads((pack / "pack.json").read_text(encoding="utf-8"))
    for key, value, expect in [("schema", "x", "schema must be"), ("id", "other", "id must be the folder name"),
                               ("version", 0, "version must be"), ("min_game", "1", "min_game must be"),
                               ("chapters", [], "chapters must be")]:
        bad = dict(good)
        bad[key] = value
        (pack / "pack.json").write_text(json.dumps(bad), encoding="utf-8")
        assert any(expect in e for e in check(pack, base_jobs, base_csv)), key
    assert cp.check_source("Bad-Id", str(pack), base_jobs, base_csv)[0].startswith("Bad-Id: bad pack id")


def pck_paths(pack):
    """What Godot exports for the fixture pack (see the real listing in docs/TECH.md §9a)."""
    prefix = "res://packs/%s/" % PID
    md5 = hashlib.md5((prefix + "arrival/demo/evening/plate.webp").encode()).hexdigest()
    paths = sorted(cp.HOUSEKEEPING) + [
        prefix + "pack.json", prefix + "arrival_scenes.json", prefix + "jobs/job.demo_one.json",
        prefix + "i18n/content.csv.import", prefix + "arrival/demo/evening/plate.webp.import",
        "res://.godot/imported/plate.webp-%s.ctex" % md5]
    paths += [prefix + "i18n/content.%s.translation" % lang for lang in cp.LANGS]
    return paths


def test_data_only_gate(tmp_path):
    pack, _base_jobs, _base_csv = make_pack(tmp_path)
    sources = cp.source_files(str(pack))
    good = pck_paths(pack)
    assert cp.check_data_only(PID, good, sources) == []
    for extra in ["res://scripts/autoload/save.gd", "res://packs/%s/patch.gd" % PID, "res://packs/%s/x.gdc" % PID,
                  "res://packs/other/jobs/job.x.json", "res://data/jobs/job.cat_bathroom.json",
                  "res://scenes/main_menu.tscn", "res://addons/lockcore_gd/bin/lib.so",
                  "res://.godot/imported/menu.png-%s.ctex" % ("0" * 32),
                  "res://.godot/exported/133200997/export-abc-main_menu.scn"]:
        errors = cp.check_data_only(PID, good + [extra], sources)
        assert any("not allowed in a data-only content pack: " + extra in e for e in errors), extra
    # something the game needs is not in the pck
    for missing in ["res://packs/%s/jobs/job.demo_one.json" % PID, "res://packs/%s/pack.json" % PID,
                    "res://packs/%s/i18n/content.pl.translation" % PID,
                    "res://packs/%s/arrival/demo/evening/plate.webp.import" % PID]:
        errors = cp.check_data_only(PID, [p for p in good if p != missing], sources)
        assert any("missing from the pck" in e for e in errors), missing


def test_content_hash_follows_sources_not_generated_files(tmp_path):
    pack, _base_jobs, _base_csv = make_pack(tmp_path)
    h = cp.content_hash(str(pack), "4.7")
    (pack / "i18n" / "content.en.translation").write_bytes(b"generated")
    assert cp.content_hash(str(pack), "4.7") == h, "Godot's .translation output is not a source"
    assert cp.content_hash(str(pack), "4.8") != h, "a new engine minor is a new pack"
    (pack / "jobs" / "job.demo_one.json").write_text(json.dumps(
        {"id": "job.demo_one", "chapter": 77, "family": "wafer", "tier": 3, "i18n": {}}), encoding="utf-8")
    assert cp.content_hash(str(pack), "4.7") != h


def test_tag_and_preset_index():
    assert cp.tag_for("ch13", 2) == "content-ch13-v2"
    assert cp.next_preset_index("[preset.0]\n[preset.0.options]\n[preset.6]\n") == 7
    preset = cp.PRESET_TEMPLATE.format(n=7, id="ch13")
    assert 'include_filter="packs/ch13/*"' in preset
    assert "*.gd," in preset and "*.gdextension" in preset


def test_mobile_presets_exclude_pack_sources():
    text = open(cp.PRESETS, encoding="utf-8").read()
    for name in ("Android", "iOS"):
        block = text.split('name="%s"' % name, 1)[1].split("[preset.", 1)[0]
        excl = [l for l in block.splitlines() if l.startswith("exclude_filter=")][0]
        assert "packs/*" in excl.split('"')[1].split(","), name


def test_repo_packs_are_valid():
    for pid in cp.discover():
        assert cp.check_source(pid, os.path.join(cp.PACKS, pid)) == [], pid
