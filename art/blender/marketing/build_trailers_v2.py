"""GEM1-v2 trailer builder: photographic key art + satin PBR cutaway renders.

Run from the repository root after rendering the v2 frame sequences:
  python art/blender/marketing/build_trailers_v2.py --frames-root out/gem1-v2/frames \
    --r13-still out/gem1-v2/R13_blank.png --out-dir out/gem1-v2/release

The R13 input MUST be a clean, text-free enamel plate, not v1 R13.mp4.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
import shutil
import subprocess
import urllib.request
import wave

import numpy as np
from PIL import Image

import build_trailers as gem1

FPS = 30
SR = 48000
ROOT = Path(__file__).resolve().parents[3]
KEYART = ROOT / 'contrib' / 'incoming' / 'magnific' / 'selected'
SUBS_V2 = ROOT / 'art' / 'marketing' / 'subtitles' / 'v2'
RELEASE_BASE = 'https://github.com/woogitsugames/lockwright/releases/download/gemini-gem1'


@dataclass(frozen=True)
class Segment:
    name: str
    frames: int
    kind: str  # art, frame, or endcard
    audio_at: float
    macro: bool = False


STORIES = {
    '30s': [
        Segment('client', 75, 'art', 0.0),
        Segment('verify', 75, 'art', 5.0),
        Segment('R04_V2_FULL', 75, 'frame', 7.0),
        Segment('R06', 60, 'frame', 11.0),
        Segment('R07', 45, 'frame', 14.0, True),
        Segment('R08', 60, 'frame', 15.5, True),
        Segment('R09', 60, 'frame', 17.5),
        Segment('R10', 90, 'frame', 19.5),
        Segment('R11', 60, 'frame', 22.5),
        Segment('R12', 60, 'frame', 24.0),
        Segment('smile', 90, 'art', 24.0),
        Segment('endcard', 150, 'endcard', 26.0),
    ],
    '15s': [
        Segment('client', 60, 'art', 0.0),
        Segment('verify', 60, 'art', 5.0),
        Segment('R04_V2_FULL', 60, 'frame', 7.0),
        Segment('R07', 30, 'frame', 14.0, True),
        Segment('R08', 30, 'frame', 15.5, True),
        Segment('R10', 60, 'frame', 19.5),
        Segment('R11', 30, 'frame', 22.5),
        Segment('smile', 60, 'art', 24.0),
        Segment('endcard', 60, 'endcard', 26.0),
    ],
}

# The crop targets are measured on the selected key art; the visual verification
# is symbolic (notebook), not an image of a real identity document.
ART = {
    'client': ('keyart_9x16.jpg', (0.53, 0.46), 1.00),
    'verify': ('keyart_1x1.jpg', (0.39, 0.54), 1.48),
    'smile': ('keyart_16x9.jpg', (0.66, 0.50), 1.04),
}

CAPTIONS = {
    'pl': {
        'client': ('Ktoś czeka w drzwiach.', '[ciche odgłosy klatki schodowej]'),
        'verify': ('Najpierw sprawdzasz prawo do lokalu.', '[szelest notesu]'),
        'R04_V2_FULL': ('Dwa kciuki, jeden mechanizm.', '[stal pod napięciem]'),
        'R06': ('Odnajdź opór.', '[chropawe tarcie mosiądzu]'),
        'R07': ('Ten pin siada.', '[suchy klik w kciuku]'),
        'R08': ('A szpulka potrafi oszukać.', '[głuchy podwójny klik]'),
        'R09': ('Cofnij nacisk.', '[ciche tarcie wsteczne]'),
        'R10': ('Kiedy gaśnie światło, zostaje słuch.', '[dwa kliknięcia w ciemności]'),
        'R11': ('Rygiel ustępuje.', '[ciężki dźwięk zasuwy]'),
        'R12': ('Drzwi otwierają się bez szkody.', '[skrzypnięcie zawiasu]'),
        'smile': ('Ktoś znowu jest w domu.', 'To gra, nie kurs. Zamki są wymyślone.'),
    },
    'en': {
        'client': ('Someone is waiting by the door.', '[a quiet stairwell]'),
        'verify': ('First, confirm they belong here.', '[a notebook page turns]'),
        'R04_V2_FULL': ('Two thumbs, one mechanism.', '[steel under tension]'),
        'R06': ('Find the resistance.', '[rough brass friction]'),
        'R07': ("That pin is set.", '[a dry click under the thumb]'),
        'R08': ('A spool can fool you.', '[a hollow double click]'),
        'R09': ('Ease the pressure.', '[a slow reverse scrape]'),
        'R10': ('When the lights go out, listen.', '[two clicks in the dark]'),
        'R11': ('The bolt gives way.', '[a heavy deadbolt clunk]'),
        'R12': ('The door opens without damage.', '[a quiet hinge creak]'),
        'smile': ("Someone's home again.", 'A game, not a course. The locks are invented.'),
    },
}


def command(args: list[str]) -> None:
    subprocess.run(args, check=True)


def validate_story(story: list[Segment], expected_seconds: int) -> None:
    actual = sum(s.frames for s in story)
    if actual != expected_seconds * FPS:
        raise ValueError(f'Story length {actual / FPS:g}s, expected {expected_seconds}s')
    assert [s.name for s in story if s.kind == 'art'] == ['client', 'verify', 'smile']
    assert story[-1].name == 'endcard'
    assert story.index(next(s for s in story if s.name == 'R04_V2_FULL')) < story.index(next(s for s in story if s.name == 'R11'))
    assert story.index(next(s for s in story if s.name == 'R11')) < story.index(next(s for s in story if s.name == 'smile'))
    macros = sum(s.frames for s in story if s.macro)
    if macros / actual > 0.4:
        raise ValueError(f'Extreme close-up share {macros / actual:.1%} exceeds 40%')
    print(f'[GEM1-v2] {expected_seconds}s: {actual} frames; extreme close-ups {macros / actual:.1%}')


def resize_focused(src: Path, dst: Path, w: int, h: int, center: tuple, zoom: float) -> None:
    if not src.is_file():
        raise FileNotFoundError(src)
    with Image.open(src) as img:
        img = img.convert('RGB')
        iw, ih = img.size
        ratio = w / h
        crop_h = min(ih, iw / ratio) / zoom
        crop_w = ratio * crop_h
        cx, cy = center[0] * iw, center[1] * ih
        left = max(0, min(iw - crop_w, cx - crop_w / 2))
        top = max(0, min(ih - crop_h, cy - crop_h / 2))
        img = img.crop((round(left), round(top), round(left + crop_w), round(top + crop_h)))
        # Preserve detail for zoompan without holding a full-resolution 4K image in RAM.
        scale = min(2.0, 2400 / w, 4200 / h)
        img = img.resize((round(w * scale), round(h * scale)), Image.Resampling.LANCZOS)
        dst.parent.mkdir(parents=True, exist_ok=True)
        img.save(dst, quality=93, subsampling=0)


def encode_keyart(segment: Segment, out: Path, temp: Path, w: int, h: int) -> None:
    name, center, zoom = ART[segment.name]
    crop = temp / f'{segment.name}_{w}x{h}.jpg'
    if not crop.exists():
        resize_focused(KEYART / name, crop, w, h, center, zoom)
    duration_frames = segment.frames
    vf = (f'zoompan=z=\'1+on*0.00035\':'
          f'x=\'(iw-iw/zoom)/2\':y=\'(ih-ih/zoom)/2\':'
          f'd={duration_frames}:s={w}x{h}:fps={FPS},setsar=1,format=yuv420p')
    command([gem1.FFMPEG, '-y', '-hide_banner', '-loglevel', 'error', '-loop', '1',
             '-framerate', str(FPS), '-i', str(crop), '-vf', vf,
             '-frames:v', str(duration_frames), '-an', '-c:v', 'libx264',
             '-preset', 'fast', '-crf', '18', '-pix_fmt', 'yuv420p', str(out)])


def encode_frames(segment: Segment, frames_root: Path, out: Path, w: int, h: int) -> None:
    folder = frames_root / segment.name
    first = folder / 'frame_0001.png'
    if not first.is_file():
        raise FileNotFoundError(f'V2 Cycles frames missing: {first} (re-render with --require_photo 1)')
    # Only allow a short tail hold; do not recycle original procedural GEM1 mp4s.
    vf = (f'fps={FPS},tpad=stop_mode=clone:stop_duration=2,'
          f'trim=end_frame={segment.frames},setpts=PTS-STARTPTS,'
          f'scale={w}:{h}:flags=lanczos,setsar=1,format=yuv420p')
    command([gem1.FFMPEG, '-y', '-hide_banner', '-loglevel', 'error',
             '-framerate', str(FPS), '-start_number', '1', '-i', str(folder / 'frame_%04d.png'),
             '-vf', vf, '-frames:v', str(segment.frames), '-an',
             '-c:v', 'libx264', '-preset', 'fast', '-crf', '18',
             '-pix_fmt', 'yuv420p', str(out)])


def encode_plate(still: Path, out: Path, frames: int, w: int, h: int) -> None:
    vf = f'scale={w}:{h}:flags=lanczos,setsar=1,format=yuv420p'
    command([gem1.FFMPEG, '-y', '-hide_banner', '-loglevel', 'error',
             '-loop', '1', '-framerate', str(FPS), '-i', str(still),
             '-vf', vf, '-frames:v', str(frames), '-an', '-c:v', 'libx264',
             '-preset', 'fast', '-crf', '18', '-pix_fmt', 'yuv420p', str(out)])


def subtitle_timestamp(frame: int) -> str:
    ms = round(frame * 1000 / FPS)
    hrs, ms = divmod(ms, 3600000)
    mins, ms = divmod(ms, 60000)
    secs, ms = divmod(ms, 1000)
    return f'{hrs:02}:{mins:02}:{secs:02},{ms:03}'


def make_srt(story: list[Segment], lang: str, path: Path) -> None:
    start = 0
    entries = []
    for s in story:
        end = start + s.frames
        if s.name in CAPTIONS[lang]:
            lines = '\n'.join(CAPTIONS[lang][s.name])
            entries.append(f'{len(entries) + 1}\n{subtitle_timestamp(start)} --> {subtitle_timestamp(end)}\n{lines}')
        start = end
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text('\n\n'.join(entries) + '\n', encoding='utf-8')


def download_wav(name: str, audio_dir: Path) -> Path:
    audio_dir.mkdir(parents=True, exist_ok=True)
    local = audio_dir / name
    if not local.is_file():
        url = f'{RELEASE_BASE}/{name}'
        print('[GEM1-v2] Fetching previous audio mix:', url)
        urllib.request.urlretrieve(url, str(local))
    return local


def retime_audio(story: list[Segment], original: Path, out: Path) -> None:
    with wave.open(str(original), 'rb') as wav:
        if (wav.getnchannels(), wav.getsampwidth(), wav.getframerate()) != (2, 2, SR):
            raise ValueError(f'Expected stereo PCM16 at {SR} Hz: {original}')
        original_data = np.frombuffer(wav.readframes(wav.getnframes()), dtype='<i2').reshape((-1, 2)).copy()
    mixed = np.zeros((sum(s.frames for s in story) * SR // FPS, 2), dtype=np.int16)
    dest_start = 0
    for s in story:
        count = s.frames * SR // FPS
        source_start = round(s.audio_at * SR)
        available = max(0, min(count, len(original_data) - source_start))
        if available:
            chunk = original_data[source_start:source_start + available].astype(np.float64)
            fade = min(int(SR * 0.012), len(chunk) // 2)
            if fade:
                chunk[:fade] *= np.linspace(0, 1, fade)[:, None]
                chunk[-fade:] *= np.linspace(1, 0, fade)[:, None]
            mixed[dest_start:dest_start + available] = chunk.astype(np.int16)
        dest_start += count
    # Last half-second fades out without introducing an availability sting.
    fade_len = min(int(SR * 0.5), len(mixed))
    mixed[-fade_len:] = (mixed[-fade_len:].astype(np.float64) * np.linspace(1, 0, fade_len)[:, None]).astype(np.int16)
    out.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(out), 'wb') as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(SR)
        wav.writeframes(mixed.tobytes())


def probe_frames(mp4: Path) -> int:
    ffprobe = shutil.which('ffprobe')
    if not ffprobe:
        return -1
    proc = subprocess.run([ffprobe, '-v', 'error', '-select_streams', 'v:0',
                           '-count_frames', '-show_entries', 'stream=nb_read_frames',
                           '-of', 'default=nw=1:nk=1', str(mp4)],
                          check=True, capture_output=True, text=True)
    return int(proc.stdout.strip())


def build(args: argparse.Namespace) -> None:
    w, h = (int(x) for x in args.size.lower().split('x'))
    if not (w > 0 and h > 0 and abs(w / h - 9 / 16) < 0.002):
        raise ValueError('Expected vertical 9:16 size, such as 1080x1920 or 2160x3840')
    frames_root = Path(args.frames_root).resolve()
    plate = Path(args.r13_still).resolve()
    out_dir = Path(args.out_dir).resolve()
    temp = out_dir / '_work'
    shots = out_dir / 'shots' / args.size
    shots.mkdir(parents=True, exist_ok=True)
    temp.mkdir(parents=True, exist_ok=True)
    if not plate.is_file():
        raise FileNotFoundError(f'Clean R13 enamel plate missing: {plate}')
    for seconds, story in STORIES.items():
        validate_story(story, int(seconds[:-1]))

    unique = {(s.name, s.frames): s for story in STORIES.values() for s in story if s.kind != 'endcard'}
    for (name, n), s in unique.items():
        path = shots / f'{name}_{n}f.mp4'
        if not path.is_file() or args.force:
            print(f'[GEM1-v2] Encoding {name}, {n} frames ({args.size})', flush=True)
            if s.kind == 'art':
                encode_keyart(s, path, temp, w, h)
            else:
                encode_frames(s, frames_root, path, w, h)
        if (found := probe_frames(path)) >= 0 and found != n:
            raise RuntimeError(f'Bad frame count {path}: {found} expected {n}')

    for lang in ('pl', 'en'):
        endcard = temp / f'R13_v2_{lang}.png'
        gem1.render_endcard_image(str(plate), str(endcard), lang=lang)
        for seconds, story in STORIES.items():
            card_key = f'R13_v2_{lang}_{story[-1].frames}f.mp4'
            card_path = shots / card_key
            if not card_path.is_file() or args.force:
                encode_plate(endcard, card_path, story[-1].frames, w, h)
            srt = SUBS_V2 / f'trailer_{seconds}_{lang}.srt'
            make_srt(story, lang, srt)
            inputs = [shots / f'{s.name}_{s.frames}f.mp4' if s.kind != 'endcard' else card_path for s in story]
            for variant in ('diegetic', 'music') if args.music else ('diegetic',):
                audio_root = Path(args.audio_dir).resolve() if args.audio_dir else temp / 'original_audio'
                original = download_wav('trailer_30s_' + variant + '.wav', audio_root)
                audio = temp / f'audio_{seconds}_{variant}.wav'
                if not audio.is_file() or args.force:
                    retime_audio(story, original, audio)
                suffix = '' if variant == 'diegetic' else '_music'
                target = out_dir / f'trailer_{seconds}_{lang}{suffix}_{args.size}.mp4'
                gem1.concat_shots_with_audio_and_srt([str(p) for p in inputs], str(audio), str(srt), str(target), str(temp))
                if variant == 'diegetic':
                    sub = out_dir / f'trailer_{seconds}_{lang}_sub_{args.size}.mp4'
                    gem1.burn_subtitles_on_video(str(target), str(srt), str(audio), str(sub), w, h, fps=FPS)
                total = sum(s.frames for s in story)
                if (found := probe_frames(target)) >= 0 and found != total:
                    raise RuntimeError(f'Bad trailer frame count: {found} != {total}: {target}')
    print('[GEM1-v2] Build complete:', out_dir)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--frames-root', required=True)
    parser.add_argument('--r13-still', required=True, help='Clean enamel plate, no text and no old store claim')
    parser.add_argument('--out-dir', required=True)
    parser.add_argument('--size', default='1080x1920', help='9:16 frame dimensions; rerun for 2160x3840')
    parser.add_argument('--audio-dir', help='Folder with original GEM1 trailer_30s_diegetic.wav and music WAV')
    parser.add_argument('--music', action='store_true', help='Also assemble S01 music variants')
    parser.add_argument('--force', action='store_true', help='Re-encode cached shots and audio')
    parser.add_argument('--validate-only', action='store_true', help='Check editorial timing without any media input')
    args = parser.parse_args()
    if args.validate_only:
        for seconds, story in STORIES.items():
            validate_story(story, int(seconds[:-1]))
        return
    build(args)


if __name__ == '__main__':
    main()
