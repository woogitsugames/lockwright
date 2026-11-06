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


def test_dynamic_key_without_csv_match_is_an_error(tmp_path):
    gd = 'var c = I18n.t(&"cast.%s.name")\n'
    findings, _ = i18n_lint.run_lint(make_root(tmp_path, gd_code=gd))
    dead = [f for f in errors(findings) if f.key == "cast.%s.name"]
    assert len(dead) == 1
    assert "no matching key" in dead[0].message


def test_dynamic_key_with_matching_csv_keys_passes(tmp_path):
    gd = ('var a = I18n.t(&"cast.%s.name")\n'
          'var b = I18n.t(&"%s.line.%d")\n'
          'var c = I18n.t(&"verify.card.%s")\n')
    root = make_root(tmp_path, gd_code=gd)
    with open(os.path.join(root, "game/i18n/content.csv"), "a", encoding="utf-8") as fh:
        fh.write("cast.hero.name,Hero,Bohater,Held\n")
        fh.write("job.test.line.1,Line one,Pierwsza linia,Erste Zeile\n")
        fh.write("verify.card.id,Identity document,Dokument tożsamości,Ausweis\n")
    findings, _ = i18n_lint.run_lint(root)
    assert errors(findings) == []
    assert not any(f.key in ("cast.%s.name", "%s.line.%d", "verify.card.%s")
                  for f in findings)


def test_dynamic_key_digit_placeholder_needs_digits(tmp_path):
    gd = 'var c = I18n.t(&"%s.line.%d")\n'
    root = make_root(tmp_path, gd_code=gd)
    with open(os.path.join(root, "game/i18n/content.csv"), "a", encoding="utf-8") as fh:
        fh.write("job.test.line.one,Line one,Pierwsza linia,Erste Zeile\n")
    findings, _ = i18n_lint.run_lint(root)
    assert any(f.key == "%s.line.%d" and f.severity == "ERROR"
               for f in findings)


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


def _write_fr_es(root, strings_rows):
    path = os.path.join(root, "game/i18n/strings.csv")
    with open(path, "w", encoding="utf-8") as fh:
        fh.write("keys,en,pl,de,fr,es\n" + "".join(r + "\n" for r in strings_rows))
    path = os.path.join(root, "game/i18n/content.csv")
    with open(path, "w", encoding="utf-8") as fh:
        fh.write("keys,en,pl,de,fr,es\njob.x.title,Title,Tytuł,Titel,Titre,Título\n")


def test_optional_fr_es_columns_may_be_empty(tmp_path):
    root = make_root(tmp_path)
    _write_fr_es(root, ["menu.play,Play,Graj,Spielen,Jouer,Jugar",
                        "common.back,Back,Wróć,Zurück,,"])
    findings, count = i18n_lint.run_lint(root)
    assert count == 3
    assert errors(findings) == []
    assert any(f.key == "[fr]" and "1/2 empty fr" in f.message for f in warns(findings))


def test_filled_fr_es_values_are_checked(tmp_path):
    root = make_root(tmp_path)
    _write_fr_es(root, ["job.reward_fmt,Reward: {n},Nagroda: {n},Belohnung: {n},Prix : {x},Premio: {n}",
                        "lock.long,Short,Krótko,Kurz,Short,Esta frase en español es demasiado larga para la pantalla",
                        "menu.bad,Play,Graj,Spielen,Jouer"])
    errs = errors(i18n_lint.run_lint(root)[0])
    assert any(f.key == "job.reward_fmt" and "fr=" in f.message for f in errs)
    assert any(f.key == "lock.long" and "es value" in f.message for f in errs)
    assert any(f.key == "menu.bad" and "malformed" in f.message for f in errs)


def test_header_optional_columns_must_be_in_order(tmp_path):
    root = make_root(tmp_path)
    with open(os.path.join(root, "game/i18n/strings.csv"), "w", encoding="utf-8") as fh:
        fh.write("keys,en,pl,de,es\nmenu.play,Play,Graj,Spielen,Jugar\n")
    assert any("bad header" in f.message for f in errors(i18n_lint.run_lint(root)[0]))
