#!/usr/bin/env bash
# Build the lockcore_gd GDExtension for Windows x86_64 (template_debug + template_release)
# with LLVM-MinGW + SCons, so headless Godot (import, GUT, pck export) works on a Windows checkout.
# The resulting DLLs land in game/addons/lockcore_gd/bin/ (gitignored, never committed).
#
# Prerequisites (one-time):
#   winget install -e --id MartinStorsjo.LLVM-MinGW.UCRT
#   python -m pip install --user scons
# godot-cpp is cloned automatically at the commit CI pins (N-28) into $GODOT_CPP.
#
# Usage (Git Bash, from anywhere):  tools/local/win_build_lockcore.sh [debug|release|all]   (default: all)
# Env overrides: GODOT_CPP, LLVM_MINGW, SCONS, JOBS.
set -euo pipefail

GODOT_CPP_COMMIT=e103d348c4b2d8df7b819126d855e19381cb9a87
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
GODOT_CPP="${GODOT_CPP:-/c/tools/godot-cpp-${GODOT_CPP_COMMIT:0:7}}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 8)}"
WHICH="${1:-all}"

# LLVM-MinGW: winget installs it under the per-user WinGet packages folder.
if [ -z "${LLVM_MINGW:-}" ]; then
  LLVM_MINGW="$(ls -d "$(cygpath -u "$LOCALAPPDATA")"/Microsoft/WinGet/Packages/MartinStorsjo.LLVM-MinGW.UCRT*/llvm-mingw-*-ucrt-x86_64 2>/dev/null | sort | tail -1 || true)"
fi
if [ -z "$LLVM_MINGW" ] || [ ! -x "$LLVM_MINGW/bin/x86_64-w64-mingw32-clang++.exe" ]; then
  echo "LLVM-MinGW not found. Install: winget install -e --id MartinStorsjo.LLVM-MinGW.UCRT (or set LLVM_MINGW)" >&2
  exit 1
fi

# SCons: pip --user puts scons.exe into %APPDATA%\Python\PythonXY\Scripts, which is often not on PATH.
if [ -z "${SCONS:-}" ]; then
  SCONS="$(command -v scons || true)"
  [ -z "$SCONS" ] && SCONS="$(ls "$(cygpath -u "$APPDATA")"/Python/Python3*/Scripts/scons.exe 2>/dev/null | sort | tail -1 || true)"
fi
if [ -z "$SCONS" ]; then
  echo "SCons not found. Install: python -m pip install --user scons (or set SCONS)" >&2
  exit 1
fi

if [ ! -f "$GODOT_CPP/SConstruct" ]; then
  echo "Cloning godot-cpp @ $GODOT_CPP_COMMIT into $GODOT_CPP"
  mkdir -p "$GODOT_CPP"
  git init -q "$GODOT_CPP"
  git -C "$GODOT_CPP" fetch -q --depth 1 https://github.com/godotengine/godot-cpp.git "$GODOT_CPP_COMMIT"
  git -C "$GODOT_CPP" checkout -q FETCH_HEAD
fi
if [ "$(git -C "$GODOT_CPP" rev-parse HEAD)" != "$GODOT_CPP_COMMIT" ]; then
  echo "WARNING: $GODOT_CPP is not at the CI-pinned commit $GODOT_CPP_COMMIT" >&2
fi

export PATH="$LLVM_MINGW/bin:$PATH"
export GODOT_CPP="$(cygpath -m "$GODOT_CPP")"
API_FILE="$GODOT_CPP/gdextension/extension_api-4-7.json"
PREFIX="$(cygpath -m "$LLVM_MINGW")"

case "$WHICH" in
  debug) TARGETS="template_debug" ;;
  release) TARGETS="template_release" ;;
  all) TARGETS="template_debug template_release" ;;
  *) echo "usage: $0 [debug|release|all]" >&2; exit 2 ;;
esac

cd "$REPO/game/addons/lockcore_gd"
for t in $TARGETS; do
  echo "== lockcore_gd windows x86_64 $t"
  "$SCONS" platform=windows target="$t" arch=x86_64 use_mingw=yes use_llvm=yes \
    mingw_prefix="$PREFIX" custom_api_file="$API_FILE" -j"$JOBS"
done
ls -l bin/*.windows.*.dll
