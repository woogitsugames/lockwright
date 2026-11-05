# Lockwright — Deterministic Trailer & Audio Assembler (30 s and 15 s, PL & EN)
# Builds:
#   - Individual encoded shot MP4s (R01..R15) from rendered frame sequences
#   - 30 s and 15 s diegetic audio mixes (48 kHz WAV) + S01 music variants
#   - End-card R13 title overlays (BonaNova-Bold + AtkinsonHyperlegibleNext in #F1EEE6 chalk)
#   - Clean MP4s (with soft SRT muxed), burned-in subtitle MP4s (_sub.mp4), and music MP4s (_music.mp4)
#   - Both 4K (2160x3840) and 1080p (1080x1920) deliverables
#
# Run:
#   python art/blender/marketing/build_trailers.py --frames_root $env:TEMP/gem1_frames --out_dir $env:TEMP/gem1_videos

import argparse
import math
import os
import re
import shutil
import struct
import subprocess
import sys
import wave

import numpy as np
from PIL import Image, ImageDraw, ImageFont

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(THIS_DIR, '..', '..', '..'))
FONTS_DIR = os.path.join(REPO_ROOT, 'mockups', 'fonts')
SUBS_DIR = os.path.join(REPO_ROOT, 'art', 'marketing', 'subtitles')

FONT_SERIF = os.path.join(FONTS_DIR, 'BonaNova-Bold.ttf')
FONT_SANS = os.path.join(FONTS_DIR, 'AtkinsonHyperlegibleNext-wght.ttf')

CHALK_RGB = (241, 238, 230)   # #F1EEE6
SHADOW_RGBA = (20, 17, 14, 215)  # #14110E warm dark backing


def find_ffmpeg() -> str:
    env_ff = os.environ.get('FFMPEG_BIN')
    if env_ff and os.path.isfile(env_ff):
        return env_ff
    which_ff = shutil.which('ffmpeg')
    if which_ff:
        return which_ff
    winget_ff = os.path.expandvars(
        r'%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg.Essentials_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-9.0.1-essentials_build\bin\ffmpeg.exe'
    )
    if os.path.isfile(winget_ff):
        return winget_ff
    raise FileNotFoundError('ffmpeg executable not found')


FFMPEG = find_ffmpeg()
SR = 48000


def load_audio_stereo_48k(rel_path: str, tmp_dir: str) -> np.ndarray:
    """Load any WAV/OGG file from repo as float32 stereo array at 48 kHz."""
    full_path = os.path.join(REPO_ROOT, rel_path)
    if not os.path.isfile(full_path):
        raise FileNotFoundError(f'Missing audio asset: {full_path}')
    os.makedirs(tmp_dir, exist_ok=True)
    cache_wav = os.path.join(tmp_dir, re.sub(r'[^a-zA-Z0-9_.-]', '_', rel_path) + '.48k.wav')
    if not os.path.isfile(cache_wav):
        subprocess.run(
            [FFMPEG, '-y', '-i', full_path, '-ar', str(SR), '-ac', '2', '-c:a', 'pcm_s16le', cache_wav],
            check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
    with wave.open(cache_wav, 'rb') as wf:
        n_frames = wf.getnframes()
        raw = wf.readframes(n_frames)
    samples = np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0
    return samples.reshape(-1, 2)


def add_clip(mix: np.ndarray, clip: np.ndarray, start_s: float, gain_db: float = 0.0,
             max_dur_s: float = None, fade_in_s: float = 0.005, fade_out_s: float = 0.02):
    """Add stereo clip into mix at start_s with gain_db and smooth fades."""
    gain = 10.0 ** (gain_db / 20.0)
    s0 = max(0, int(round(start_s * SR)))
    if s0 >= len(mix):
        return
    seg = clip.copy()
    if max_dur_s is not None:
        max_len = int(round(max_dur_s * SR))
        seg = seg[:max_len]
    avail = min(len(seg), len(mix) - s0)
    if avail <= 0:
        return
    seg = seg[:avail] * gain
    fi = min(avail, int(round(fade_in_s * SR)))
    fo = min(avail, int(round(fade_out_s * SR)))
    if fi > 1:
        seg[:fi] *= np.linspace(0.0, 1.0, fi, dtype=np.float32)[:, None]
    if fo > 1:
        seg[-fo:] *= np.linspace(1.0, 0.0, fo, dtype=np.float32)[:, None]
    mix[s0:s0 + avail] += seg


def add_haptic_sub(mix: np.ndarray, start_s: float, freq_hz: float = 60.0, dur_s: float = 0.085, gain_db: float = -18.0):
    """Synthesize low-frequency haptic sub-layer (40-90 Hz, -18 dB under clicks per MARKETING.md §0)."""
    n = int(round(dur_s * SR))
    t = np.arange(n, dtype=np.float32) / SR
    # Pitch drop envelope for tactile brass/steel thud
    f_inst = freq_hz * np.exp(-t * 8.0) + 42.0 * (1.0 - np.exp(-t * 8.0))
    phase = 2.0 * np.pi * np.cumsum(f_inst) / SR
    env = np.sin(np.pi * np.minimum(1.0, t / 0.008)) * np.exp(-t / (dur_s * 0.38))
    sig = (np.sin(phase) * env).astype(np.float32)
    stereo = np.column_stack([sig, sig])
    add_clip(mix, stereo, start_s, gain_db=gain_db, fade_in_s=0.002, fade_out_s=0.015)


def save_normalized_wav(path: str, mix: np.ndarray, target_peak_db: float = -1.0):
    """Soft-limit and normalize stereo mix to target true-peak ceiling (-1.0 dBTP)."""
    peak = float(np.max(np.abs(mix)))
    target_amp = 10.0 ** (target_peak_db / 20.0)
    if peak > 1e-6:
        # Gentle tanh saturation if hot, then exact peak normalization
        scaled = mix * (target_amp / peak)
    else:
        scaled = mix
    pcm = np.clip(scaled * 32767.0, -32768, 32767).astype(np.int16)
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    with wave.open(path, 'wb') as wf:
        wf.setnchannels(2)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(pcm.tobytes())


def build_audio_tracks(tmp_dir: str, out_dir: str):
    """Build 30s and 15s diegetic and music-mixed WAV tracks."""
    stairwell = load_audio_stereo_48k('audio/v2/out/ambience/stairwell.wav', tmp_dir)
    night_timer = load_audio_stereo_48k('audio/v2/out/ambience/night_timer.wav', tmp_dir)
    roll_open = load_audio_stereo_48k('audio/v2/out/ui/tool_roll_open_1.wav', tmp_dir)
    pick_sel = load_audio_stereo_48k('game/assets/audio/ui/pick_insert_01.wav', tmp_dir)
    wrench_set = load_audio_stereo_48k('game/assets/audio/ui/loupe_set_down_01.wav', tmp_dir)
    paper_rst = load_audio_stereo_48k('audio/v2/out/ui/paper_slide_1.wav', tmp_dir)

    bind1 = load_audio_stereo_48k('audio/v2/out/sfx/bind/brass_1.wav', tmp_dir)
    bind2 = load_audio_stereo_48k('audio/v2/out/sfx/bind/brass_2.wav', tmp_dir)
    bind3 = load_audio_stereo_48k('audio/v2/out/sfx/bind/brass_3.wav', tmp_dir)
    near1 = load_audio_stereo_48k('audio/v2/out/sfx/near_shear/brass_1.wav', tmp_dir)
    set1 = load_audio_stereo_48k('audio/v2/out/sfx/set/brass_1.wav', tmp_dir)
    set2 = load_audio_stereo_48k('audio/v2/out/sfx/set/brass_2.wav', tmp_dir)
    set3 = load_audio_stereo_48k('audio/v2/out/sfx/set/brass_3.wav', tmp_dir)
    set4 = load_audio_stereo_48k('audio/v2/out/sfx/set/brass_4.wav', tmp_dir)
    fset1 = load_audio_stereo_48k('audio/v2/out/sfx/false_set/brass_1.wav', tmp_dir)
    crot1 = load_audio_stereo_48k('audio/v2/out/sfx/counter_rotate/brass_1.wav', tmp_dir)
    open1 = load_audio_stereo_48k('audio/v2/out/sfx/open/brass_1.wav', tmp_dir)
    door_rew = load_audio_stereo_48k('audio/v2/out/reward/door_open_1.wav', tmp_dir)

    bulb_off = load_audio_stereo_48k('contrib/gpt/S02/foley/light_bulb_off_01.wav', tmp_dir)
    hinge1 = load_audio_stereo_48k('contrib/gpt/S02/foley/door_hinge_01.wav', tmp_dir)

    mus_harmony = load_audio_stereo_48k('contrib/gpt/S01/audio/lock_harmony.ogg', tmp_dir)
    mus_door = load_audio_stereo_48k('contrib/gpt/S01/audio/jingle_door_open.ogg', tmp_dir)

    # ---------------- 30s DIEGETIC TRACK ----------------
    mix30 = np.zeros((30 * SR, 2), dtype=np.float32)
    # Stairwell air bed (0..19.65s, then ultra-quiet room tone in darkness, returning at 24.0..29.5s)
    add_clip(mix30, np.tile(stairwell, (3, 1)), 0.0, gain_db=-14.0, max_dur_s=19.65, fade_in_s=0.2, fade_out_s=0.15)
    # 100 Hz ballast hum after timer switch clicks on at 0.33s until timer switch clicks off at 19.65s
    add_clip(mix30, np.tile(night_timer, (3, 1)), 0.33, gain_db=-13.0, max_dur_s=19.32, fade_in_s=0.18, fade_out_s=0.08)
    add_clip(mix30, np.tile(stairwell, (2, 1)), 24.0, gain_db=-13.5, max_dur_s=5.5, fade_in_s=0.3, fade_out_s=1.2)

    # R01 (0.0-2.5s): stairwell timer switch click at frame 10 (0.33s)
    add_clip(mix30, bulb_off, 0.30, gain_db=-2.0)
    add_haptic_sub(mix30, 0.32, freq_hz=75.0, dur_s=0.06, gain_db=-18.0)

    # R02 (2.5-5.0s): leather unrolling + clink of spring steel
    add_clip(mix30, roll_open, 2.55, gain_db=-1.5)
    add_clip(mix30, pick_sel, 3.45, gain_db=-4.0)

    # R03 (5.0-7.0s): paper rustle of envelope
    add_clip(mix30, paper_rst, 5.15, gain_db=-5.0)

    # R04 (7.0-10.0s): dry metal sliding into brass keyway
    add_clip(mix30, pick_sel, 7.35, gain_db=-2.5)
    add_clip(mix30, wrench_set, 8.15, gain_db=-2.0)

    # R05 (10.0-11.0s): metallic bind, low thrum
    add_clip(mix30, wrench_set, 10.12, gain_db=-1.0)
    add_clip(mix30, bind1, 10.28, gain_db=-1.5)
    add_haptic_sub(mix30, 10.25, freq_hz=55.0, dur_s=0.11, gain_db=-18.0)

    # R06 (11.0-14.0s): gritty brass-on-steel friction
    add_clip(mix30, bind2, 11.20, gain_db=-1.0)
    add_clip(mix30, near1, 12.10, gain_db=-1.0)
    add_clip(mix30, bind3, 13.00, gain_db=-1.0)
    add_haptic_sub(mix30, 12.10, freq_hz=62.0, dur_s=0.09, gain_db=-18.0)

    # R07 (14.0-15.5s): crisp high set click (3.2 kHz) at frame 8 (~14.25s)
    add_clip(mix30, set1, 14.24, gain_db=0.0)
    add_haptic_sub(mix30, 14.24, freq_hz=68.0, dur_s=0.075, gain_db=-18.0)

    # R08 (15.5-17.5s): hollow double click of spool false set (1.1 kHz) at ~15.80s
    add_clip(mix30, fset1, 15.78, gain_db=0.0)
    add_haptic_sub(mix30, 15.78, freq_hz=50.0, dur_s=0.07, gain_db=-18.0)
    add_haptic_sub(mix30, 15.89, freq_hz=46.0, dur_s=0.08, gain_db=-18.0)

    # R09 (17.5-19.5s): slow reverse scrape + high set click
    add_clip(mix30, crot1, 17.75, gain_db=-0.5)
    add_clip(mix30, set2, 18.62, gain_db=0.0)
    add_haptic_sub(mix30, 18.62, freq_hz=66.0, dur_s=0.075, gain_db=-18.0)

    # R10 (19.5-22.5s): timer switch clicks off -> silence -> two crisp set clicks in the dark
    add_clip(mix30, bulb_off, 19.62, gain_db=-1.0)
    add_haptic_sub(mix30, 19.62, freq_hz=72.0, dur_s=0.05, gain_db=-18.0)
    add_clip(mix30, set3, 20.80, gain_db=0.5)
    add_haptic_sub(mix30, 20.80, freq_hz=65.0, dur_s=0.08, gain_db=-18.0)
    add_clip(mix30, set4, 21.73, gain_db=0.5)
    add_haptic_sub(mix30, 21.73, freq_hz=70.0, dur_s=0.08, gain_db=-18.0)

    # R11 (22.5-24.0s): heavy low deadbolt clunk (220 Hz)
    add_clip(mix30, open1, 22.70, gain_db=0.5)
    add_clip(mix30, door_rew, 22.82, gain_db=-1.0)
    add_haptic_sub(mix30, 22.72, freq_hz=45.0, dur_s=0.14, gain_db=-18.0)

    # R12 (24.0-26.0s): soft hinge creak, stairwell air
    add_clip(mix30, hinge1, 24.12, gain_db=-2.0)

    # R13 (26.0-30.0s): single tap of a pick set down on wood at 26.35s, then 1s silence before end
    add_clip(mix30, pick_sel, 26.35, gain_db=-2.0)

    wav30_diegetic = os.path.join(out_dir, 'trailer_30s_diegetic.wav')
    save_normalized_wav(wav30_diegetic, mix30, target_peak_db=-1.0)

    # 30s WITH S01 MUSIC (quietly under mechanism, ducks out completely when light goes out at 19.6s)
    mix30_mus = mix30.copy()
    add_clip(mix30_mus, mus_harmony, 2.5, gain_db=-17.5, max_dur_s=17.1, fade_in_s=1.5, fade_out_s=0.25)
    add_clip(mix30_mus, mus_door, 24.0, gain_db=-14.0, max_dur_s=4.5, fade_in_s=0.1, fade_out_s=1.2)
    wav30_music = os.path.join(out_dir, 'trailer_30s_music.wav')
    save_normalized_wav(wav30_music, mix30_mus, target_peak_db=-1.0)

    # ---------------- 15s DIEGETIC TRACK ----------------
    mix15 = np.zeros((15 * SR, 2), dtype=np.float32)
    add_clip(mix15, stairwell, 0.0, gain_db=-15.0, max_dur_s=9.65, fade_in_s=0.1, fade_out_s=0.1)
    add_clip(mix15, night_timer, 0.0, gain_db=-14.5, max_dur_s=9.65, fade_in_s=0.1, fade_out_s=0.08)

    # 0.0-1.0s (R05): dry steel slide-in, tension click
    add_clip(mix15, pick_sel, 0.08, gain_db=-2.0)
    add_clip(mix15, wrench_set, 0.25, gain_db=-1.0)
    add_clip(mix15, bind1, 0.50, gain_db=-1.5)
    add_haptic_sub(mix15, 0.25, freq_hz=56.0, dur_s=0.09, gain_db=-18.0)

    # 1.0-4.0s (R06): gritty brass friction
    add_clip(mix15, bind2, 1.20, gain_db=-1.0)
    add_clip(mix15, near1, 2.15, gain_db=-1.0)
    add_clip(mix15, bind3, 3.05, gain_db=-1.0)
    add_haptic_sub(mix15, 2.15, freq_hz=62.0, dur_s=0.08, gain_db=-18.0)

    # 4.0-5.5s (R07): crisp set click (3.2 kHz)
    add_clip(mix15, set1, 4.24, gain_db=0.0)
    add_haptic_sub(mix15, 4.24, freq_hz=68.0, dur_s=0.075, gain_db=-18.0)

    # 5.5-7.5s (R08): hollow double click (1.1 kHz)
    add_clip(mix15, fset1, 5.78, gain_db=0.0)
    add_haptic_sub(mix15, 5.78, freq_hz=50.0, dur_s=0.07, gain_db=-18.0)
    add_haptic_sub(mix15, 5.89, freq_hz=46.0, dur_s=0.08, gain_db=-18.0)

    # 7.5-9.5s (R09): reverse scrape, set click
    add_clip(mix15, crot1, 7.75, gain_db=-0.5)
    add_clip(mix15, set2, 8.62, gain_db=0.0)
    add_haptic_sub(mix15, 8.62, freq_hz=66.0, dur_s=0.075, gain_db=-18.0)

    # 9.5-11.5s (R10): switch click -> darkness -> set click
    add_clip(mix15, bulb_off, 9.62, gain_db=-1.0)
    add_haptic_sub(mix15, 9.62, freq_hz=72.0, dur_s=0.05, gain_db=-18.0)
    add_clip(mix15, set3, 10.75, gain_db=0.5)
    add_haptic_sub(mix15, 10.75, freq_hz=68.0, dur_s=0.08, gain_db=-18.0)

    # 11.5-13.0s (R11): heavy deadbolt clunk (220 Hz)
    add_clip(mix15, open1, 11.70, gain_db=0.5)
    add_clip(mix15, door_rew, 11.82, gain_db=-1.0)
    add_haptic_sub(mix15, 11.72, freq_hz=45.0, dur_s=0.14, gain_db=-18.0)

    # 13.0-15.0s (R13): single tool tap
    add_clip(mix15, pick_sel, 13.30, gain_db=-2.0)

    wav15_diegetic = os.path.join(out_dir, 'trailer_15s_diegetic.wav')
    save_normalized_wav(wav15_diegetic, mix15, target_peak_db=-1.0)

    mix15_mus = mix15.copy()
    add_clip(mix15_mus, mus_harmony, 0.0, gain_db=-17.5, max_dur_s=9.6, fade_in_s=0.6, fade_out_s=0.2)
    add_clip(mix15_mus, mus_door, 11.7, gain_db=-14.5, max_dur_s=3.0, fade_in_s=0.08, fade_out_s=0.8)
    wav15_music = os.path.join(out_dir, 'trailer_15s_music.wav')
    save_normalized_wav(wav15_music, mix15_mus, target_peak_db=-1.0)

    return {
        '30s_diegetic': wav30_diegetic,
        '30s_music': wav30_music,
        '15s_diegetic': wav15_diegetic,
        '15s_music': wav15_music,
    }


def render_endcard_image(bg_png_path: str, out_png_path: str, lang: str = 'pl'):
    """Render LOCKWRIGHT title and localized identity subtitle onto R13 enamel plate."""
    im = Image.open(bg_png_path).convert('RGBA')
    W, H = im.size
    overlay = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    title_size = max(24, int(round(W * 0.068)))
    sub_size = max(16, int(round(W * 0.027)))
    f_title = ImageFont.truetype(FONT_SERIF, title_size)
    f_sub = ImageFont.truetype(FONT_SANS, sub_size)

    title_txt = 'LOCKWRIGHT'
    sub_txt = 'Pogotowie Zamkowe' if lang == 'pl' else 'Locksmith on Call'

    # Enamel plate sits centered horizontally and right around Y = 0.49 * H (well inside 14%..80% safe area)
    cx = W // 2
    cy_title = int(round(H * 0.468))
    cy_sub = int(round(H * 0.518))

    for dx, dy in [(-2, 2), (2, 2), (0, 3)]:
        draw.text((cx + dx, cy_title + dy), title_txt, font=f_title, fill=(14, 18, 28, 160), anchor='mm')
        draw.text((cx + dx, cy_sub + dy), sub_txt, font=f_sub, fill=(14, 18, 28, 160), anchor='mm')

    draw.text((cx, cy_title), title_txt, font=f_title, fill=(*CHALK_RGB, 255), anchor='mm')
    draw.text((cx, cy_sub), sub_txt, font=f_sub, fill=(*CHALK_RGB, 235), anchor='mm')

    out_im = Image.alpha_composite(im, overlay).convert('RGB')
    os.makedirs(os.path.dirname(os.path.abspath(out_png_path)), exist_ok=True)
    out_im.save(out_png_path, format='PNG', compress_level=6)


def parse_srt(srt_path: str):
    """Parse .srt file into list of (start_s, end_s, lines)."""
    with open(srt_path, 'r', encoding='utf-8') as f:
        text = f.read().strip()
    blocks = re.split(r'\n\s*\n', text)
    entries = []
    for b in blocks:
        lines = [ln.strip() for ln in b.strip().splitlines() if ln.strip()]
        if len(lines) < 2:
            continue
        tc_line = lines[1] if '-->' in lines[1] else lines[0]
        m = re.match(
            r'(\d+):(\d+):(\d+)[,.](\d+)\s*-->\s*(\d+):(\d+):(\d+)[,.](\d+)',
            tc_line
        )
        if not m:
            continue
        vals = [int(x) for x in m.groups()]
        t0 = vals[0] * 3600 + vals[1] * 60 + vals[2] + vals[3] / 1000.0
        t1 = vals[4] * 3600 + vals[5] * 60 + vals[6] + vals[7] / 1000.0
        txt_lines = lines[2:] if '-->' in lines[1] else lines[1:]
        entries.append((t0, t1, txt_lines))
    return entries


def encode_shot_mp4(frames_dir: str, out_mp4: str, fps: int = 30, width: int = None, height: int = None):
    """Encode frame_%04d.png sequence to H.264 High Profile MP4."""
    os.makedirs(os.path.dirname(os.path.abspath(out_mp4)), exist_ok=True)
    in_pattern = os.path.join(frames_dir, 'frame_%04d.png')
    cmd = [
        FFMPEG, '-y',
        '-framerate', str(fps),
        '-i', in_pattern,
    ]
    if width and height:
        cmd += ['-vf', f'scale={width}:{height}:flags=lanczos']
    cmd += [
        '-c:v', 'libx264',
        '-profile:v', 'high',
        '-pix_fmt', 'yuv420p',
        '-crf', '16',
        '-preset', 'fast',
        '-movflags', '+faststart',
        out_mp4
    ]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def encode_still_hold_mp4(still_png: str, out_mp4: str, num_frames: int, fps: int = 30, width: int = None, height: int = None):
    """Encode a static PNG for exact num_frames at fps."""
    os.makedirs(os.path.dirname(os.path.abspath(out_mp4)), exist_ok=True)
    dur = num_frames / float(fps)
    cmd = [
        FFMPEG, '-y',
        '-loop', '1',
        '-framerate', str(fps),
        '-i', still_png,
        '-frames:v', str(num_frames),
    ]
    if width and height:
        cmd += ['-vf', f'scale={width}:{height}:flags=lanczos']
    cmd += [
        '-c:v', 'libx264',
        '-profile:v', 'high',
        '-pix_fmt', 'yuv420p',
        '-crf', '16',
        '-preset', 'fast',
        '-movflags', '+faststart',
        out_mp4
    ]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def burn_subtitles_on_video(in_mp4: str, srt_path: str, audio_wav: str, out_mp4: str, width: int, height: int, fps: int = 30):
    """Render crisp subtitle plates in Pillow respecting 9:16 safe area (bottom >= 20% margin, sides >= 7.5%)
    and composite over in_mp4 via FFmpeg overlay filter."""
    entries = parse_srt(srt_path)
    tmp_sub_dir = os.path.join(os.path.dirname(out_mp4), '_tmp_subs_' + os.path.basename(out_mp4))
    os.makedirs(tmp_sub_dir, exist_ok=True)

    font_main_sz = max(20, int(round(width * 0.036)))
    font_sdh_sz = max(16, int(round(width * 0.026)))
    f_main = ImageFont.truetype(FONT_SERIF, font_main_sz)
    f_sdh = ImageFont.truetype(FONT_SANS, font_sdh_sz)

    # Safe area: bottom 20% free -> place subtitle block centered around Y = 0.755 * height
    safe_y_bottom = int(round(height * 0.785))
    cx = width // 2

    overlay_inputs = []
    filter_chains = []

    for idx, (t0, t1, lines) in enumerate(entries):
        # Skip burning redundant title text on R13 if R13 already has the enamel plate title,
        # keep only the SDH bracket line on R13 so text doesn't double up
        filtered_lines = []
        for ln in lines:
            if ln.startswith('LOCKWRIGHT —'):
                continue
            filtered_lines.append(ln)
        if not filtered_lines:
            continue

        im = Image.new('RGBA', (width, height), (0, 0, 0, 0))
        draw = ImageDraw.Draw(im)

        line_heights = []
        for ln in filtered_lines:
            is_sdh = ln.startswith('[')
            f_use = f_sdh if is_sdh else f_main
            bbox = draw.textbbox((0, 0), ln, font=f_use)
            line_heights.append((ln, f_use, is_sdh, bbox[2] - bbox[0], bbox[3] - bbox[1]))

        total_h = sum(x[4] for x in line_heights) + max(0, len(line_heights) - 1) * int(round(height * 0.012))
        max_w = max(x[3] for x in line_heights)

        pad_x = int(round(width * 0.025))
        pad_y = int(round(height * 0.010))
        y_top = safe_y_bottom - total_h

        # Subtle warm-dark backing pill (#14110E @ 82% alpha) for legibility without obscuring mechanism
        rect = [cx - max_w // 2 - pad_x, y_top - pad_y, cx + max_w // 2 + pad_x, safe_y_bottom + pad_y]
        draw.rounded_rectangle(rect, radius=int(round(width * 0.012)), fill=SHADOW_RGBA)

        cur_y = y_top
        for ln, f_use, is_sdh, lw, lh in line_heights:
            col = (225, 220, 210, 235) if is_sdh else (*CHALK_RGB, 255)
            draw.text((cx, cur_y + lh // 2), ln, font=f_use, fill=col, anchor='mm')
            cur_y += lh + int(round(height * 0.012))

        png_path = os.path.join(tmp_sub_dir, f'sub_{idx:02d}.png')
        im.save(png_path, format='PNG')
        overlay_inputs.append((png_path, t0, t1))

    cmd = [FFMPEG, '-y', '-i', in_mp4, '-i', audio_wav]
    for png_path, _, _ in overlay_inputs:
        cmd += ['-i', png_path]

    if overlay_inputs:
        fc = []
        prev = '[0:v]'
        for i, (_, t0, t1) in enumerate(overlay_inputs):
            inp = f'[{i + 2}:v]'
            nxt = f'[v{i + 1}]'
            fc.append(f"{prev}{inp}overlay=0:0:enable='between(t,{t0:.3f},{t1:.3f})'{nxt}")
            prev = nxt
        cmd += ['-filter_complex', ';'.join(fc), '-map', prev, '-map', '1:a:0']
    else:
        cmd += ['-map', '0:v:0', '-map', '1:a:0']

    cmd += [
        '-c:v', 'libx264', '-profile:v', 'high', '-pix_fmt', 'yuv420p', '-crf', '17', '-preset', 'fast',
        '-c:a', 'aac', '-b:a', '256k', '-ar', str(SR),
        '-movflags', '+faststart',
        out_mp4
    ]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    shutil.rmtree(tmp_sub_dir, ignore_errors=True)


def concat_shots_with_audio_and_srt(shot_mp4s: list, audio_wav: str, srt_path: str, out_mp4: str, tmp_dir: str):
    """Concatenate shot MP4s (cut-to-cut, zero cross-dissolves) and mux stereo audio + soft SRT subtitle track."""
    concat_txt = os.path.join(tmp_dir, 'concat_' + os.path.basename(out_mp4) + '.txt')
    with open(concat_txt, 'w', encoding='utf-8') as f:
        for p in shot_mp4s:
            safe_p = os.path.abspath(p).replace('\\', '/')
            f.write(f"file '{safe_p}'\n")

    cmd = [
        FFMPEG, '-y',
        '-f', 'concat', '-safe', '0', '-i', concat_txt,
        '-i', audio_wav,
    ]
    if srt_path and os.path.isfile(srt_path):
        cmd += ['-i', srt_path, '-map', '0:v:0', '-map', '1:a:0', '-map', '2:s:0', '-c:s', 'mov_text']
    else:
        cmd += ['-map', '0:v:0', '-map', '1:a:0']

    cmd += [
        '-c:v', 'copy',
        '-c:a', 'aac', '-b:a', '256k', '-ar', str(SR),
        '-movflags', '+faststart',
        out_mp4
    ]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--frames_root', required=True, help='Directory containing R01..R15 frame subdirectories')
    parser.add_argument('--r13_still', required=True, help='Path to rendered R13 blank enamel plate 2160x3840 PNG')
    parser.add_argument('--out_dir', required=True, help='Output directory for encoded shots and trailers')
    args = parser.parse_args()

    frames_root = os.path.abspath(args.frames_root)
    out_dir = os.path.abspath(args.out_dir)
    shots_4k_dir = os.path.join(out_dir, 'shots_4k')
    shots_1080p_dir = os.path.join(out_dir, 'shots_1080p')
    tmp_dir = os.path.join(out_dir, '_tmp_build')
    os.makedirs(shots_4k_dir, exist_ok=True)
    os.makedirs(shots_1080p_dir, exist_ok=True)
    os.makedirs(tmp_dir, exist_ok=True)

    print('[build_trailers] Building diegetic and music audio tracks...')
    audio_paths = build_audio_tracks(tmp_dir, out_dir)

    # Render PL and EN R13 endcard PNGs
    r13_pl_png = os.path.join(tmp_dir, 'R13_endcard_pl_2160x3840.png')
    r13_en_png = os.path.join(tmp_dir, 'R13_endcard_en_2160x3840.png')
    render_endcard_image(args.r13_still, r13_pl_png, lang='pl')
    render_endcard_image(args.r13_still, r13_en_png, lang='en')

    # Encode individual shots R01..R12, R14, R15 in 4K (2160x3840) and 1080p (1080x1920)
    shot_ids = ['R01', 'R02', 'R03', 'R04', 'R05', 'R06', 'R07', 'R08', 'R09', 'R10', 'R11', 'R12', 'R14', 'R15']
    for sid in shot_ids:
        fdir = os.path.join(frames_root, sid)
        if not os.path.isdir(fdir):
            raise FileNotFoundError(f'Missing rendered frame directory for {sid}: {fdir}')
        print(f'[build_trailers] Encoding {sid} (4K & 1080p)...')
        encode_shot_mp4(fdir, os.path.join(shots_4k_dir, f'{sid}.mp4'), fps=30)
        encode_shot_mp4(fdir, os.path.join(shots_1080p_dir, f'{sid}_1080p.mp4'), fps=30, width=1080, height=1920)

    # R10 for 15s trailer needs first 60 frames (2.0 s)
    r10_60f_dir = os.path.join(tmp_dir, 'R10_60f')
    os.makedirs(r10_60f_dir, exist_ok=True)
    for k in range(1, 61):
        src_f = os.path.join(frames_root, 'R10', f'frame_{k:04d}.png')
        dst_f = os.path.join(r10_60f_dir, f'frame_{k:04d}.png')
        if not os.path.exists(dst_f):
            shutil.copy2(src_f, dst_f)
    encode_shot_mp4(r10_60f_dir, os.path.join(shots_4k_dir, 'R10_60f.mp4'), fps=30)
    encode_shot_mp4(r10_60f_dir, os.path.join(shots_1080p_dir, 'R10_60f_1080p.mp4'), fps=30, width=1080, height=1920)

    # Encode R13 holds: 120 frames (4.0s for 30s trailer) and 60 frames (2.0s for 15s trailer), PL and EN
    for lang, png_p in [('pl', r13_pl_png), ('en', r13_en_png)]:
        encode_still_hold_mp4(png_p, os.path.join(shots_4k_dir, f'R13_120f_{lang}.mp4'), 120, fps=30)
        encode_still_hold_mp4(png_p, os.path.join(shots_1080p_dir, f'R13_120f_{lang}_1080p.mp4'), 120, fps=30, width=1080, height=1920)
        encode_still_hold_mp4(png_p, os.path.join(shots_4k_dir, f'R13_60f_{lang}.mp4'), 60, fps=30)
        encode_still_hold_mp4(png_p, os.path.join(shots_1080p_dir, f'R13_60f_{lang}_1080p.mp4'), 60, fps=30, width=1080, height=1920)

    # Also save standalone R13.mp4 (PL) in shots_4k and shots_1080p
    shutil.copy2(os.path.join(shots_4k_dir, 'R13_120f_pl.mp4'), os.path.join(shots_4k_dir, 'R13.mp4'))
    shutil.copy2(os.path.join(shots_1080p_dir, 'R13_120f_pl_1080p.mp4'), os.path.join(shots_1080p_dir, 'R13_1080p.mp4'))

    # Assemble 30s and 15s trailers in 4K (2160x3840) and 1080p (1080x1920)
    for res_tag, sdir, w, h in [
        ('', shots_4k_dir, 2160, 3840),
        ('_1080p', shots_1080p_dir, 1080, 1920),
    ]:
        sfx_ext = '_1080p.mp4' if res_tag else '.mp4'
        for lang in ('pl', 'en'):
            srt30 = os.path.join(SUBS_DIR, f'trailer_30s_{lang}.srt')
            srt15 = os.path.join(SUBS_DIR, f'trailer_15s_{lang}.srt')

            seq30 = [os.path.join(sdir, f'{s}{sfx_ext}') for s in ['R01', 'R02', 'R03', 'R04', 'R05', 'R06', 'R07', 'R08', 'R09', 'R10', 'R11', 'R12']]
            seq30.append(os.path.join(sdir, f'R13_120f_{lang}{sfx_ext}'))

            seq15 = [os.path.join(sdir, f'{s}{sfx_ext}') for s in ['R05', 'R06', 'R07', 'R08', 'R09']]
            seq15.append(os.path.join(sdir, f'R10_60f{sfx_ext}'))
            seq15.append(os.path.join(sdir, f'R11{sfx_ext}'))
            seq15.append(os.path.join(sdir, f'R13_60f_{lang}{sfx_ext}'))

            # 1) Clean diegetic MP4 (with muxed soft SRT)
            out30_clean = os.path.join(out_dir, f'trailer_30s_{lang}{res_tag}.mp4')
            out15_clean = os.path.join(out_dir, f'trailer_15s_{lang}{res_tag}.mp4')
            print(f'[build_trailers] Assembling {os.path.basename(out30_clean)} & {os.path.basename(out15_clean)}...')
            concat_shots_with_audio_and_srt(seq30, audio_paths['30s_diegetic'], srt30, out30_clean, tmp_dir)
            concat_shots_with_audio_and_srt(seq15, audio_paths['15s_diegetic'], srt15, out15_clean, tmp_dir)

            # 2) S01 Music MP4 (with muxed soft SRT)
            out30_mus = os.path.join(out_dir, f'trailer_30s_{lang}_music{res_tag}.mp4')
            out15_mus = os.path.join(out_dir, f'trailer_15s_{lang}_music{res_tag}.mp4')
            print(f'[build_trailers] Assembling {os.path.basename(out30_mus)} & {os.path.basename(out15_mus)}...')
            concat_shots_with_audio_and_srt(seq30, audio_paths['30s_music'], srt30, out30_mus, tmp_dir)
            concat_shots_with_audio_and_srt(seq15, audio_paths['15s_music'], srt15, out15_mus, tmp_dir)

            # 3) Burned-in subtitle MP4 (_sub.mp4)
            out30_sub = os.path.join(out_dir, f'trailer_30s_{lang}_sub{res_tag}.mp4')
            out15_sub = os.path.join(out_dir, f'trailer_15s_{lang}_sub{res_tag}.mp4')
            print(f'[build_trailers] Burning subtitles for {os.path.basename(out30_sub)} & {os.path.basename(out15_sub)}...')
            burn_subtitles_on_video(out30_clean, srt30, audio_paths['30s_diegetic'], out30_sub, w, h, fps=30)
            burn_subtitles_on_video(out15_clean, srt15, audio_paths['15s_diegetic'], out15_sub, w, h, fps=30)

    print('[build_trailers] ALL TRAILERS AND SHOTS BUILT SUCCESSFULLY.')


if __name__ == '__main__':
    main()
