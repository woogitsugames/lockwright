# Warded readability — 2026-11-06

Final: `../warded.png`, 1620×2160, 128 spp, Blender 4.2.9 / RTX 5070 OptiX. Reproduce with `LW_DEVICE=GPU blender -b -P art/blender/warded_contrast.py -- --out art/renders/warded.png --res 1620x2160 --samples 128 --ward-key 100000`.

The wrapper loads the existing warded scene and adds a linked area key for the ward arcs and their rivets. Camera, geometry and materials remain the original scene. This is a render-only readability light; it does not alter game assets or logic.

Six outer-ward samples at 45, 135, 180, 225, 270 and 315 degrees use 13×13-pixel median linear-sRGB luminance, with contrast `(Lighter + 0.05)/(Darker + 0.05)`. Nearby backplate sample patches are checked by camera ray casts at their centre and four corners. Minimum adjacent contrast: **3.09:1**, compared with 1.51–2.04:1 before. This verifies those six regions, not every pixel in the image.

`measurements.json` also retains the separate backplate points farther from the ward edge; all six exceed 3:1 in the final. `sample_locations.jpg`: white squares = ward, red squares = farther case samples, cyan circles = adjacent case. `before_after.jpg` includes grayscale comparison. Baseline blob and render parameters are in `render_info.json`.
