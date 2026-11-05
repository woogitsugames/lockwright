# Lockwright — Marketing family renders (R17)
# Wrapper around art/blender/{wafer,warded,lever,wooden_pin,ring_combo}.py
# without modifying original files. Renders in 2160x3840 (9:16) with Cycles GPU (OptiX),
# Albedo+Normal denoising, and use_dof = False.
#
# Usage:
#   blender -b -P art/blender/marketing/families_render.py -- --family wafer --state free --out art/marketing/stills/R17_wafer_free.png --res 2160x3840 --samples 256
#   blender -b -P art/blender/marketing/families_render.py -- --family wafer --state set  --out art/marketing/stills/R17_wafer_set.png  --res 2160x3840 --samples 256

import bpy
import os
import sys

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
BLENDER_DIR = os.path.abspath(os.path.join(THIS_DIR, '..'))
for p in (THIS_DIR, BLENDER_DIR):
    if p not in sys.path:
        sys.path.insert(0, p)

import lw_common
from gpu_common import setup_gpu_cycles, ensure_under_10mb

arg = lw_common.cli()
FAMILY = arg('--family', 'wafer')
STATE = arg('--state', 'free')  # 'free' (diagnostic/mixed) or 'set' (aligned/solved)
OUT = arg('--out', f'art/marketing/previews/R17_{FAMILY}_{STATE}.png')
RES_STR = arg('--res', '2160x3840')
RES = [int(v) for v in RES_STR.split('x')]
SAMPLES = int(arg('--samples', '256'))

# Adjust default camera distance for 9:16 portrait so horizontal framing matches 3:4 look-dev
# and keeps the entire mechanism inside the 9:16 safe area (top 14%, bottom 20%, sides 7.5%).
IS_PORTRAIT_9_16 = (RES[1] > RES[0] and (RES[1] / max(1, RES[0])) > 1.5)
FAMILY_DIST_9_16 = {
    'wafer': '88',
    'warded': '330',
    'lever': '220',
    'wooden_pin': '590',
    'ring_combo': '335',
}


def patch_source_for_state(family: str, state: str, src: str) -> str:
    """Adjust state table in script source in-memory without touching original files on disk."""
    if state != 'set':
        return src

    if family == 'wafer':
        # All 5 wafers aligned at the shear line (dz=0.0), hook lifted under w3
        old = "STATE = [('set', 0.0, 0.0, 0.0), ('set', 0.0, 0.0, 0.0), ('bind', -0.7, 1.3, 0.06), ('over', 1.4, 0.0, 0.0), ('free', -1.8, 0.0, 0.0)]"
        new = "STATE = [('set', 0.0, 0.0, 0.0), ('set', 0.0, 0.0, 0.0), ('set', 0.0, 0.0, 0.0), ('set', 0.0, 0.0, 0.0), ('set', 0.0, 0.0, 0.0)]"
        src = src.replace(old, new)
        src = src.replace("(16.95, 0.9 - 0.48)", "(16.95, 1.6)")
    elif family == 'warded':
        # Tumbler lifted cleanly above bolt notch (1.65 mm clear light gap), bit rotated to 82 deg
        src = src.replace("arg('--angle', '76')", "arg('--angle', '82')")
        src = src.replace("arg('--lift', '1.38')", "arg('--lift', '1.68')")
    elif family == 'lever':
        # All 3 levers lifted into their gate channels (actual lift == needed lift)
        old = "    (0.9, 3.5, 1.5, -11.2),\n    (4.1, 2.5, 2.5, -12.0),\n    (7.3, 3.0, 5.0, -11.6),"
        new = "    (0.9, 3.5, 3.5, -11.2),\n    (4.1, 2.5, 2.5, -12.0),\n    (7.3, 3.0, 3.0, -11.6),"
        src = src.replace(old.replace('\n', '\r\n'), new.replace('\n', '\r\n')).replace(old, new)
    elif family == 'wooden_pin':
        # All 3 gravity pins lifted cleanly to the shear line (lift = 8.0 mm), bolt free to slide
        old = "STATES = [('set', 8.0, 0.0), ('bind', 5.0, 2.0), ('free', 0.0, 0.0)]"
        new = "STATES = [('set', 8.0, 0.0), ('set', 8.0, 0.0), ('set', 8.0, 0.0)]"
        src = src.replace(old, new)
    elif family == 'ring_combo':
        # All 4 combination rings rotated to their true gates (0 deg), spindle lugs seated in gates
        old = "STATES = [('set', 0, 0.0), ('bind', 144, 0.0), ('false', 0, 0.0), ('free', 252, 0.8)]"
        new = "STATES = [('set', 0, 0.0), ('set', 0, 0.0), ('set', 0, 0.0), ('set', 0, 0.0)]"
        src = src.replace(old, new)
    return src


def run_family(family: str, state: str, out_path: str):
    script_path = os.path.join(BLENDER_DIR, f'{family}.py')
    if not os.path.isfile(script_path):
        raise FileNotFoundError(f'Unknown family script: {script_path}')

    with open(script_path, 'r', encoding='utf-8') as f:
        src = f.read()

    src = patch_source_for_state(family, state, src)

    # Override render_setup in lw_common to enforce Cycles GPU OptiX + no DOF
    orig_render_setup = lw_common.render_setup

    def gpu_render_setup(out, res, samples=128, exposure=0.0, crop=None):
        os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
        orig_render_setup(out_path, RES, SAMPLES, exposure=exposure, crop=crop)
        setup_gpu_cycles(bpy.context.scene, samples=SAMPLES, use_dof=False)

    lw_common.render_setup = gpu_render_setup

    # Inject portrait camera distance if not explicitly overridden on CLI
    if IS_PORTRAIT_9_16 and '--dist' not in sys.argv and family in FAMILY_DIST_9_16:
        sys.argv.extend(['--dist', FAMILY_DIST_9_16[family]])
    if IS_PORTRAIT_9_16 and family == 'ring_combo' and '--tx' not in sys.argv:
        sys.argv.extend(['--tx', '-10'])

    ns = {
        '__file__': script_path,
        '__name__': '__main__',
    }
    exec(compile(src, script_path, 'exec'), ns)
    ensure_under_10mb(os.path.abspath(out_path))


run_family(FAMILY, STATE, OUT)
