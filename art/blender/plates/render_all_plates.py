"""Batch runner for all 4 Lockwright photoreal lock family plate scripts."""
import os
import subprocess
import sys
import time

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
SCRIPTS = [
    "wafer_plate.py",
    "lever_plate.py",
    "warded_plate.py",
    "wooden_pin_plate.py",
]


def main():
    blender_bin = os.environ.get(
        "BLENDER_BIN",
        r"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe",
    )
    t0 = time.time()
    for script in SCRIPTS:
        script_path = os.path.join(THIS_DIR, script)
        print(f"=== Running {script} ===", flush=True)
        subprocess.run([blender_bin, "-b", "-P", script_path], check=True)
    print(f"=== All 4 family plates finished in {time.time() - t0:.1f}s ===", flush=True)


if __name__ == "__main__":
    main()
