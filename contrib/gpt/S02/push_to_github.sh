#!/bin/sh
# Publish only the files under contrib/gpt/S02 to the requested repository.
# Run from a local authenticated clone of woogitsugames/lockwright.
set -eu
repo=$(git rev-parse --show-toplevel)
cd "$repo"
case "$(git remote get-url origin)" in
  *woogitsugames/lockwright* ) ;;
  * ) echo "Unexpected GitHub remote; refusing." >&2; exit 2 ;;
esac
if [ ! -d contrib/gpt/S02 ]; then
  echo "Copy extracted S02 folder to contrib/gpt/S02 before running." >&2
  exit 2
fi
git fetch origin main
if [ "$(git rev-parse --abbrev-ref HEAD)" != main ]; then
  echo "Switch to main yourself before running this helper." >&2
  exit 2
fi
git merge --ff-only origin/main
git add -- contrib/gpt/S02
if git diff --cached --quiet; then
  echo "No S02 changes to commit."
  exit 0
fi
if git diff --cached --name-only | grep -v '^contrib/gpt/S02/' >/dev/null; then
  echo "Other paths were already staged; refusing a mixed commit." >&2
  exit 2
fi
git commit -m 'contrib/gpt/S02: add tenement ambience and foley'
git push origin main
