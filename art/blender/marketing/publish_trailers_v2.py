"""Validate and upload finished GEM1-v2 videos to GitHub Release via authenticated gh CLI."""
import argparse
import shutil
import subprocess
from pathlib import Path

REPO = 'woogitsugames/lockwright'
TAG = 'gemini-gem1-v2'
SIZES = ('1080x1920', '2160x3840')


def run(cmd):
    return subprocess.run(cmd, check=True, text=True, capture_output=True)


def check_video(path: Path, duration: int):
    probe = shutil.which('ffprobe')
    if not probe:
        raise RuntimeError('ffprobe is required to check release assets')
    result = run([probe, '-v', 'error', '-select_streams', 'v:0', '-count_frames',
                  '-show_entries', 'stream=nb_read_frames', '-of', 'default=nk=1:nw=1', str(path)])
    actual = int(result.stdout.strip())
    if actual != duration * 30:
        raise RuntimeError(f'{path}: expected {duration * 30} frames, got {actual}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', required=True, help='Directory with 1080/ and 4k/ build outputs')
    parser.add_argument('--no-music', action='store_true', help='Allow missing music variant')
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()
    gh = shutil.which('gh')
    if not gh and not args.dry_run:
        raise RuntimeError('GitHub CLI (gh) is required; authenticate with gh auth login')
    root = Path(args.root).resolve()
    files = []
    for size in SIZES:
        for seconds in (30, 15):
            for lang in ('pl', 'en'):
                for variant in ('', '_sub') + (() if args.no_music else ('_music',)):
                    matches = sorted(root.rglob(f'trailer_{seconds}s_{lang}{variant}_{size}.mp4'))
                    if len(matches) != 1:
                        raise RuntimeError(f'Expected exactly 1 trailer_{seconds}s_{lang}{variant}_{size}.mp4 under {root}; got {len(matches)}')
                    check_video(matches[0], seconds)
                    files.append(matches[0])
    print(f'GEM1-v2 verified: {len(files)} assets (2 durations, 2 languages, 2 resolutions)')
    print('\n'.join(str(f) for f in files))
    if args.dry_run:
        return
    try:
        run([gh, 'release', 'view', TAG, '--repo', REPO])
    except subprocess.CalledProcessError:
        run([gh, 'release', 'create', TAG, '--repo', REPO,
             '--title', 'GEM1-v2 — zwiastuny (animatik)',
             '--notes', 'Zwiastuny 30 s i 15 s (PL/EN). Zgodne z D-49. Materiały Blender + Magnific; animatik, nie nagranie z gry. Bez deklaracji dostępności.'])
    for file in files:
        run([gh, 'release', 'upload', TAG, str(file), '--repo', REPO, '--clobber'])
        print('UPLOADED', file.name, flush=True)
    print(f'RELEASE https://github.com/{REPO}/releases/tag/{TAG}')


if __name__ == '__main__':
    main()
