import os
import shutil

import assets_lint

DATA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data", "assets")


def make_root(tmp_path, assets_md=None):
    root = tmp_path / "repo"
    docs = root / "docs"
    docs.mkdir(parents=True)
    src = assets_md or os.path.join(DATA, "ASSETS.md")
    shutil.copy(src, docs / "ASSETS.md")
    return str(root)


def add_file(root, rel, size=8):
    path = os.path.join(root, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as fh:
        fh.write(b"\0" * size)
    return path


def errors(findings):
    return [f for f in findings if f.severity == "ERROR"]


def test_listed_assets_pass(tmp_path):
    root = make_root(tmp_path)
    add_file(root, "game/assets/ui/icons/play.png")
    add_file(root, "game/assets/audio/sfx/click.wav")
    add_file(root, "game/assets/audio/sfx/hum.ogg")
    add_file(root, "game/assets/models/a.glb")
    add_file(root, "game/assets/models/b.glb")
    findings, stats = assets_lint.run_lint(root)
    assert errors(findings) == []
    assert stats["unlisted"] == []


def test_unlisted_binary_is_an_error(tmp_path):
    root = make_root(tmp_path)
    add_file(root, "game/assets/ui/icons/play.png")
    add_file(root, "game/assets/stray.bin.png")
    findings, stats = assets_lint.run_lint(root)
    assert stats["unlisted"] == ["game/assets/stray.bin.png"]
    assert any("stray.bin.png" in f.location for f in errors(findings))


def test_import_files_are_skipped(tmp_path):
    root = make_root(tmp_path)
    add_file(root, "game/assets/stray.png.import")
    findings, stats = assets_lint.run_lint(root)
    assert stats["unlisted"] == []


def test_directory_entry_covers_files(tmp_path):
    root = make_root(tmp_path)
    add_file(root, "game/assets/ui/icons/play.png")
    with open(os.path.join(root, "docs/ASSETS.md"), "a", encoding="utf-8") as fh:
        fh.write("\n| game/assets/ui/icons | grafika | własne | własne | — |\n")
    findings, stats = assets_lint.run_lint(root)
    assert stats["unlisted"] == []


def test_bare_filename_sibling_does_not_cover_other_directories(tmp_path):
    # Review V01: "mockups/fonts/GameFont.ttf, OtherFont.ttf" used to let the bare
    # sibling name cover game/assets/**/OtherFont.ttf (false negative).
    root = make_root(tmp_path)
    add_file(root, "game/assets/fonts/StrayFont.ttf")
    with open(os.path.join(root, "docs/ASSETS.md"), "a", encoding="utf-8") as fh:
        fh.write("\n| mockups/fonts/GameFont.ttf, StrayFont.ttf | font | test | OFL | — |\n")
    findings, stats = assets_lint.run_lint(root)
    assert stats["unlisted"] == ["game/assets/fonts/StrayFont.ttf"]
    assert any("StrayFont.ttf" in f.location for f in errors(findings))


def test_comma_list_sibling_inherits_the_list_directory(tmp_path):
    # A bare filename in a comma list is relative to the sibling paths of the same
    # list, so it covers the file in that directory and nowhere else.
    root = make_root(tmp_path)
    add_file(root, "game/assets/ui/tray.jpg")
    add_file(root, "game/assets/ui/section.jpg")
    with open(os.path.join(root, "docs/ASSETS.md"), "a", encoding="utf-8") as fh:
        fh.write("\n| game/assets/ui/tray.jpg, section.jpg | grafika | własne | własne | — |\n")
    findings, stats = assets_lint.run_lint(root)
    assert stats["unlisted"] == []


def test_backtick_sibling_inherits_the_line_directory(tmp_path):
    # Rows like "| `game/assets/ui/hand.png`, `thumb.png` (note) | ..." list
    # siblings in separate backticks: the bare name is relative to the
    # directory of the same line and nowhere else.
    root = make_root(tmp_path)
    add_file(root, "game/assets/ui/thumb.png")
    add_file(root, "game/assets/fonts/thumb.png")
    with open(os.path.join(root, "docs/ASSETS.md"), "a", encoding="utf-8") as fh:
        fh.write("\n| `game/assets/ui/hand.png`, `thumb.png` (note) | grafika |"
                 " własne | własne | — |\n")
    findings, stats = assets_lint.run_lint(root)
    assert stats["unlisted"] == ["game/assets/fonts/thumb.png"]


def test_brace_sibling_inherits_the_line_directory(tmp_path):
    # A brace expansion such as `plate_{normal,pressed}.png` yields bare names;
    # they are relative to the directory named earlier in the same line.
    root = make_root(tmp_path)
    add_file(root, "game/assets/ui/plate_normal.png")
    add_file(root, "game/assets/ui/plate_pressed.png")
    with open(os.path.join(root, "docs/ASSETS.md"), "a", encoding="utf-8") as fh:
        fh.write("\n| `game/assets/ui/base_{normal,pressed}.png`,"
                 " `plate_{normal,pressed}.png` | grafika | własne | własne | — |\n")
    findings, stats = assets_lint.run_lint(root)
    assert stats["unlisted"] == []


def test_path_suffix_entry_covers_with_a_directory(tmp_path):
    root = make_root(tmp_path)
    add_file(root, "game/assets/fonts/GameFont.ttf")
    with open(os.path.join(root, "docs/ASSETS.md"), "a", encoding="utf-8") as fh:
        fh.write("\n| assets/fonts/GameFont.ttf | font | test | OFL | — |\n")
    findings, stats = assets_lint.run_lint(root)
    assert stats["unlisted"] == []


def test_lone_bare_filename_entry_matches_nothing(tmp_path):
    root = make_root(tmp_path)
    add_file(root, "game/assets/fonts/UnlistedFont.ttf")
    with open(os.path.join(root, "docs/ASSETS.md"), "a", encoding="utf-8") as fh:
        fh.write("\n| UnlistedFont.ttf | font | test | OFL | — |\n")
    findings, stats = assets_lint.run_lint(root)
    assert stats["unlisted"] == ["game/assets/fonts/UnlistedFont.ttf"]


def test_font_ofl_via_txt_file_and_via_assets_md(tmp_path):
    root = make_root(tmp_path)
    add_file(root, "game/assets/fonts/GameFont.ttf")
    add_file(root, "game/assets/fonts/OFL.txt")
    add_file(root, "game/assets/fonts/OtherFont.ttf")
    findings, stats = assets_lint.run_lint(root)
    assert stats["missing_ofl"] == []


def test_font_without_ofl_is_an_error(tmp_path):
    root = make_root(tmp_path)
    add_file(root, "game/assets/fonts/NoLicense.ttf")
    findings, stats = assets_lint.run_lint(root)
    assert stats["missing_ofl"] == ["game/assets/fonts/NoLicense.ttf"]


def test_oversized_file_is_an_error_and_top20_is_capped(tmp_path):
    root = make_root(tmp_path)
    add_file(root, "game/assets/ui/icons/play.png", size=assets_lint.MAX_BYTES + 1)
    for i in range(25):
        add_file(root, f"game/assets/audio/sfx/s{i:02d}.wav", size=100 + i)
    findings, stats = assets_lint.run_lint(root)
    assert stats["oversized"] == ["game/assets/ui/icons/play.png"]
    assert len(stats["top"]) == assets_lint.TOP_N
    assert stats["top"][0][1] == "game/assets/ui/icons/play.png"
    assert any("8 MB" in f.message for f in errors(findings))


def test_report_exit_code(tmp_path, capsys):
    root = make_root(tmp_path)
    add_file(root, "game/assets/ui/icons/play.png")
    findings, stats = assets_lint.run_lint(root)
    assert assets_lint.print_report(findings, stats) == 0
    add_file(root, "game/assets/stray.png")
    findings, stats = assets_lint.run_lint(root)
    assert assets_lint.print_report(findings, stats) == 1
