#!/usr/bin/env python3
"""Prints the onboarding walk (qa/bot/onboarding.gd) as a short table; exit 1 when the walk did not finish.

Usage: onboarding_report.py report.json
"""
import json
import sys


def main() -> int:
    try:
        rep = json.load(open(sys.argv[1], encoding="utf-8"))
    except (OSError, ValueError, IndexError) as e:
        print("onboarding: no report (%s)" % e)
        return 1
    print("onboarding walk: lang=%s profile=%s two_thumbs=%s end=%s" % (
        rep.get("lang"), rep.get("profile"), rep.get("two_thumbs"), rep.get("end")))
    print("%-34s %8s %5s %7s %7s %6s %9s" % ("mark", "t [s]", "taps", "screens", "wait[s]", "words", "human[s]"))
    for name, m in sorted(rep.get("marks", {}).items(), key=lambda kv: kv[1]["t"]):
        print("%-34s %8.1f %5d %7d %7.1f %6d %9.1f" % (
            name, m["t"], m["taps"], m["screens"], m["wait_s"], m["words"], m.get("human_estimate_s", 0.0)))
    for lock in rep.get("locks", []):
        print("lock %-18s %-12s t%s %-8s open %5.1fs  then %4.1fs  lines %d (%d words)" % (
            lock["lock"], lock["family"], lock["tier"], lock.get("player", "?"), lock.get("open_s", -1.0),
            lock.get("after_open_s", 0.0), len(lock.get("lines", {})), lock.get("line_words", 0)))
    for p in rep.get("problems", []):
        print("PROBLEM t=%s %s: %s" % (p.get("t"), p.get("screen"), p.get("problem")))
    return 0 if rep.get("end") == "done" and not rep.get("problems") else 1


if __name__ == "__main__":
    sys.exit(main())
