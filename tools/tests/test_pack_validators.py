"""Content validators read content packs too (D-112, D-115): data/tools/validate.py, data/tools/loc_qa.py,
tools/i18n_lint.py and tools/voice_lines.py see game/packs/<id>/ next to game/data/jobs and game/i18n.

The fixture pack lives in tools/tests/data/packs/ch77 (never under game/packs) and is copied into a temporary repo."""
import importlib.util
import json
import os
import shutil

import i18n_lint
import voice_lines

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
I18N_DATA = os.path.join(HERE, "data", "i18n", "valid")
PACK_DATA = os.path.join(HERE, "data", "packs", "ch77")
PACK_CSV = "game/packs/ch77/i18n/content.csv"


def load_tool(name):
    """data/tools is not a package and not on sys.path: load the script by file."""
    spec = importlib.util.spec_from_file_location(name, os.path.join(REPO, "data", "tools", name + ".py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


validate = load_tool("validate")
loc_qa = load_tool("loc_qa")


def make_root(tmp_path, with_pack=True):
    """A tiny repo: base i18n fixture, one base job, empty tools/progression, optionally the fixture pack."""
    root = tmp_path / "repo"
    game = root / "game"
    (game / "i18n").mkdir(parents=True)
    for name in ("strings.csv", "content.csv"):
        shutil.copy(os.path.join(I18N_DATA, name), game / "i18n" / name)
    with open(game / "i18n" / "content.csv", "a", encoding="utf-8", newline="") as f:
        f.write("job.test.title,Test job,Zlecenie próbne,Testauftrag\n"
                "job.test.line.1,Good evening.,Dobry wieczór.,Guten Abend.\n")
    (game / "data" / "jobs").mkdir(parents=True)
    (game / "data" / "jobs" / "job.test.json").write_text(
        json.dumps({"id": "job.test", "chapter": 1, "lines": ["client"]}), encoding="utf-8")
    (game / "data" / "tools.json").write_text('{"tools": []}', encoding="utf-8")
    (game / "data" / "progression.json").write_text('{"families": []}', encoding="utf-8")
    if with_pack:
        shutil.copytree(PACK_DATA, game / "packs" / "ch77")
    return root


def pack_file(root, rel):
    return root / "game" / "packs" / "ch77" / rel


def append_pack_row(root, row):
    with open(pack_file(root, "i18n/content.csv"), "a", encoding="utf-8", newline="") as f:
        f.write(row + "\n")


def lint_errors(root):
    findings, key_count = i18n_lint.run_lint(str(root))
    return [f for f in findings if f.severity == "ERROR"], key_count


# --- data/tools/validate.py ---

def test_validate_counts_pack_jobs(tmp_path, capsys):
    assert validate.main(str(make_root(tmp_path))) == 0
    assert "validated: 2 jobs (1 in 1 content packs)" in capsys.readouterr().out


def test_validate_without_packs_is_unchanged(tmp_path, capsys):
    assert validate.main(str(make_root(tmp_path, with_pack=False))) == 0
    assert "validated: 1 jobs (0 in 0 content packs)" in capsys.readouterr().out


def test_validate_pack_job_needs_its_texts(tmp_path, capsys):
    root = make_root(tmp_path)
    csv_path = pack_file(root, "i18n/content.csv")
    text = csv_path.read_text(encoding="utf-8")
    csv_path.write_text("".join(l for l in text.splitlines(True) if ".client," not in l), encoding="utf-8")
    assert validate.main(str(root)) == 1
    assert "job job.fixture_cellar: missing i18n key job.fixture_cellar.client" in capsys.readouterr().out


def test_validate_pack_job_finds_texts_only_in_its_pack_csv(tmp_path, capsys):
    """The base content.csv has no row of the pack job: reading packs is what makes it pass."""
    root = make_root(tmp_path)
    os.remove(pack_file(root, "i18n/content.csv"))
    assert validate.main(str(root)) == 1
    assert "missing i18n key job.fixture_cellar.title" in capsys.readouterr().out


def test_validate_duplicate_job_id_across_base_and_pack(tmp_path, capsys):
    root = make_root(tmp_path)
    shutil.copy(root / "game" / "data" / "jobs" / "job.test.json", pack_file(root, "jobs/job.test.json"))
    assert validate.main(str(root)) == 1
    assert "duplicate job id: job.test" in capsys.readouterr().out


def test_validate_invalid_pack_job_json(tmp_path, capsys):
    root = make_root(tmp_path)
    pack_file(root, "jobs/job.broken.json").write_text("{", encoding="utf-8")
    assert validate.main(str(root)) == 1
    assert "invalid JSON" in capsys.readouterr().out


def test_validate_pack_key_clashing_with_base(tmp_path, capsys):
    root = make_root(tmp_path)
    append_pack_row(root, "job.test.title,A,B,C,D,E")
    assert validate.main(str(root)) == 1
    assert "i18n key job.test.title already defined in game/i18n/content.csv" in capsys.readouterr().out


def test_validate_pack_scene_must_belong_to_a_pack_job(tmp_path, capsys):
    root = make_root(tmp_path)
    pack_file(root, "arrival_scenes.json").write_text(json.dumps(
        {"scenes": {"job.test": {"dir": "res://packs/ch77/arrival/x", "times": ["evening"]}}}), encoding="utf-8")
    assert validate.main(str(root)) == 1
    assert "game/packs/ch77/arrival_scenes.json: scene for unknown job job.test" in capsys.readouterr().out


def test_validate_base_scene_for_a_job_moved_to_a_pack(tmp_path, capsys):
    """A scene entry left behind in game/data after its job moved into a pack is reported."""
    root = make_root(tmp_path)
    (root / "game" / "data" / "arrival_scenes.json").write_text(json.dumps(
        {"scenes": {"job.test": {}, "job.fixture_cellar": {}}}), encoding="utf-8")
    assert validate.main(str(root)) == 1
    out = capsys.readouterr().out
    assert "game/data/arrival_scenes.json: scene for unknown job job.fixture_cellar" in out
    assert "unknown job job.test" not in out


# --- data/tools/loc_qa.py ---

def test_loc_qa_lists_pack_csv(tmp_path):
    root = make_root(tmp_path)
    rels = [os.path.relpath(p, str(root)).replace(os.sep, "/") for p in loc_qa.csv_paths(str(root))]
    assert rels == ["game/i18n/strings.csv", "game/i18n/content.csv", PACK_CSV]
    assert loc_qa.main(str(root)) == 0


def test_loc_qa_flags_polish_in_pack_en(tmp_path, capsys):
    root = make_root(tmp_path)
    append_pack_row(root, "job.fixture_cellar.note,Klucz jest w piwnicy,Klucz jest w piwnicy,K,C,L")
    assert loc_qa.main(str(root)) == 1
    assert "FAIL Polish in EN: job.fixture_cellar.note" in capsys.readouterr().out


def test_loc_qa_flags_empty_pl_in_pack(tmp_path, capsys):
    root = make_root(tmp_path)
    append_pack_row(root, "job.fixture_cellar.note,A note,,Notiz,Note,Nota")
    assert loc_qa.main(str(root)) == 1
    assert "FAIL empty: job.fixture_cellar.note" in capsys.readouterr().out


# --- tools/i18n_lint.py ---

def test_lint_reads_pack_csv(tmp_path):
    errors, key_count = lint_errors(make_root(tmp_path))
    assert errors == []
    assert key_count == 8 + 5  # base fixture + two rows added by make_root, plus the pack's five


def test_lint_without_packs_is_unchanged(tmp_path):
    errors, key_count = lint_errors(make_root(tmp_path, with_pack=False))
    assert errors == []
    assert key_count == 8


def test_lint_pack_placeholder_mismatch(tmp_path):
    root = make_root(tmp_path)
    append_pack_row(root, "job.fixture_cellar.note,{n} keys,{m} kluczy,{n} Schlüssel,{n} clés,{n} llaves")
    errors, _ = lint_errors(root)
    assert [f.key for f in errors] == ["job.fixture_cellar.note"]
    assert errors[0].location.startswith(PACK_CSV + ":")
    assert "placeholder mismatch" in errors[0].message


def test_lint_pack_empty_required_language(tmp_path):
    root = make_root(tmp_path)
    append_pack_row(root, "job.fixture_cellar.note,A note,Notatka,,Note,Nota")
    errors, _ = lint_errors(root)
    assert len(errors) == 1 and "empty value in column 'de'" in errors[0].message


def test_lint_pack_key_already_in_base(tmp_path):
    root = make_root(tmp_path)
    append_pack_row(root, "menu.play,Play,Graj,Spielen,Jouer,Jugar")
    errors, _ = lint_errors(root)
    assert len(errors) == 1
    assert errors[0].key == "menu.play"
    assert "already defined in game/i18n/strings.csv" in errors[0].message


def test_lint_code_key_resolved_by_pack_csv(tmp_path):
    root = make_root(tmp_path)
    scripts = root / "game" / "scripts"
    scripts.mkdir()
    (scripts / "sample.gd").write_text('var a = I18n.t(&"job.fixture_cellar.title")\n', encoding="utf-8")
    errors, _ = lint_errors(root)
    assert errors == []


# --- tools/voice_lines.py ---

def test_voice_inventory_includes_pack_lines(tmp_path):
    game = make_root(tmp_path) / "game"
    inv = voice_lines.inventory("line", game=game)
    assert [(l["key"], l["speaker"]) for l in inv] == [
        ("job.test.line.1", "client"),
        ("job.fixture_cellar.line.1", "client"),
        ("job.fixture_cellar.line.2", "locksmith"),
    ]
    assert inv[1]["text"]["fr"] == "La clé a cassé, il y a {n} jours."
    after = voice_lines.inventory("after", game=game)
    assert [l["key"] for l in after] == ["job.fixture_cellar.after.1"]
    assert voice_lines.inventory("wrong_open", game=game) == []


def test_voice_inventory_without_packs(tmp_path):
    game = make_root(tmp_path, with_pack=False) / "game"
    assert [l["key"] for l in voice_lines.inventory("line", game=game)] == ["job.test.line.1"]


def test_fixture_pack_is_not_a_real_pack():
    """The fixture must never be picked up as a game pack by the build."""
    assert not os.path.exists(os.path.join(REPO, "game", "packs", "ch77"))
