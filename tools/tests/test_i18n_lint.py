import os
import shutil

import i18n_lint

DATA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data", "i18n")


def make_root(tmp_path, fixture="valid", gd_code=None):
    root = tmp_path / "repo"
    i18n_dir = root / "game" / "i18n"
    i18n_dir.mkdir(parents=True, exist_ok=True)
    for name in ("strings.csv", "content.csv"):
        shutil.copy(os.path.join(DATA, fixture, name), i18n_dir / name)
    if gd_code is not None:
        scripts = root / "game" / "scripts"
        scripts.mkdir(parents=True)
        (scripts / "sample.gd").write_text(gd_code, encoding="utf-8")
    return str(root)


def errors(findings):
    return [f for f in findings if f.severity == "ERROR"]


def warns(findings):
    return [f for f in findings if f.severity == "WARN"]


def test_valid_fixture_has_no_errors(tmp_path):
    findings, key_count = i18n_lint.run_lint(make_root(tmp_path))
    assert key_count == 6
    assert errors(findings) == []


def test_code_keys_must_exist_in_csv(tmp_path):
    gd = ('var a = I18n.t(&"menu.play")\n'
          'var b = I18n.t("common.back")\n'
          'var c = I18n.t(&"missing.key")\n')
    findings, _ = i18n_lint.run_lint(make_root(tmp_path, gd_code=gd))
    missing = [f for f in errors(findings) if "missing.key" in f.key]
    assert len(missing) == 1
    assert "sample.gd:3" in missing[0].location


def test_dynamic_keys_are_warnings_not_errors(tmp_path):
    gd = 'var c = I18n.t(&"cast.%s.name")\n'
    findings, _ = i18n_lint.run_lint(make_root(tmp_path, gd_code=gd))
    assert errors(findings) == []
    dyn = [f for f in warns(findings) if f.key == "cast.%s.name"]
    assert len(dyn) == 1


def test_invalid_fixture_reports_all_error_kinds(tmp_path):
    findings, _ = i18n_lint.run_lint(make_root(tmp_path, fixture="invalid"))
    errs = errors(findings)
    messages = " | ".join(f"{f.key}:{f.message}" for f in errs)
    assert any(f.key == "menu.play" and "duplicate" in f.message for f in errs)
    assert any(f.key == "common.back" and "empty value" in f.message for f in errs)
    assert any(f.key == "job.bad.row" and "malformed" in f.message for f in errs)
    assert any(f.key == "job.reward_fmt" and "placeholder" in f.message for f in errs)
    assert any(f.key == "tutorial.too_long" and "limit" in f.message for f in errs)
    assert any(f.key == "lock.too_long_de" and "de value" in f.message for f in errs)
    assert "limit" in messages


def test_warnings_for_quotes_untranslated_and_banned_word(tmp_path):
    findings, _ = i18n_lint.run_lint(make_root(tmp_path, fixture="invalid"))
    w = warns(findings)
    assert any(f.key == "warn.quotes" and "quote" in f.message for f in w)
    assert any(f.key == "warn.untranslated" and "identical to en" in f.message for f in w)
    assert any(f.key == "warn.banned" and "włam" in f.message for f in w)


def test_menu_length_limit(tmp_path):
    root = make_root(tmp_path)
    path = os.path.join(root, "game/i18n/strings.csv")
    with open(path, "a", encoding="utf-8") as fh:
        fh.write("menu.long,This menu label is way too long,Za długa etykieta menu,Zu langes Menülabel\n")
    findings, _ = i18n_lint.run_lint(root)
    assert any(f.key == "menu.long" and f.severity == "ERROR" and "28" in f.message
               for f in findings)


def test_report_exit_code_only_on_errors(tmp_path, capsys):
    findings, count = i18n_lint.run_lint(make_root(tmp_path))
    assert i18n_lint.print_report(findings, count) == 0
    findings, count = i18n_lint.run_lint(make_root(tmp_path, fixture="invalid"))
    assert i18n_lint.print_report(findings, count) == 1
