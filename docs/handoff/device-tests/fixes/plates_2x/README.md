# GPU plates, 2026-11-06

Blender 4.2.9 LTS, NVIDIA GeForce RTX 5070, Cycles OptiX, photo materials.
One 2472x3300 pin smoke render at 16 spp matched the existing camera and geometry at the same scale before the final batch.

Finals: pin, warded, wafer, lever at 2472x3300 / 128 spp; dial_safe, combo, disc_detainer, egyptian, time_lock, axial_slider at 1236x1648 / 256 spp; magnetic/dimple tools at 48 px/mm / 128 spp.
Warded parts, plate and wards were rendered together from the same material revision. Lever has an additional parts_detector pass.

All published PNGs have a tracked lossy import (quality 0.85). See import-sizes.json for resolutions and measured CTEX sizes. Each *_crop_1to1.jpg compares the previous image enlarged 2x with a native crop of the GPU final. final_overview.jpg shows all ten families.

Godot 4.7.2 local Android pack on the rebased main (session A menu D-62): 55,833,660 bytes without detector; **57,799,088 bytes (57.80 MB) including the five-lever detector**, within the 58 MB budget. N-68 initially blocked integration on the earlier main (58,142,664 bytes); the independently landed menu changes freed 343,576 bytes, so the same detector now fits. No game code or export filter was changed locally.


The local Windows checkout has no Windows lockcore GDExtension. Godot wrote the complete resource pack, but returned exit code 1 with missing-library and preset.2.options diagnostics. This is a resource-size measurement, not a passing runtime/export test. Session A must confirm the authoritative Linux perf-budget and Android build. GUT opening tests cannot be validated on this Windows checkout.

Detector: five canonical rest poses (lift == need), required GLB nodes verified, unchanged gate dimensions; projected gate separation 33.17–39.31 dp at width 412 dp. A deeper case accommodates five leaves, their springs, washers, stump and pawl. No REST_DELTA_LIFT or GATE_HALF_H changes are needed. Runtime visual alignment and both-mode opening remain for session A / CI; resource budget now passes locally.
