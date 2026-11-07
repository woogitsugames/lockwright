# Local session log

## Current handoff status

All authorized GPU art is rendered: ready-family 2x game plates, five-lever model/photo plates, arrival sequences/stills, menu in three languages/orientations with all pressed states, and warded contrast (six adjacent samples >=3.09:1). Final portrait menu board is 73.89% wide; integration remains session A decision.

Device evidence covers all twelve previously ready families and owner-confirmed PL/EN speech. Session A has implemented fixes for startup, Android Back, haptics, missing menu assets and detector opening; device retest of the new fixes awaits a successful Android artifact. Full S1–S3/two-thumb/H0–H4 signoff remains open. Magnific D1/D2 are still missing, so final character shadows/composites are blocked.

## 2026-11-06 — GPU plates and Android evidence

- Host: RTX 5070, Blender 4.2.9 LTS; Python 3.14 with Pillow/NumPy already installed. Godot 4.7.2, standard export templates and Android platform-tools installed with owner approval.
- GPU opt-in: `LW_DEVICE=GPU`, OptiX then CUDA, default CPU preserved. Separate commit `52753f1c` pushed.
- One 2472×3300 / 16 spp pin smoke render checked against the original at equal scale before finals; no camera/part alignment shift observed.
- Final plates completed: pin / warded / wafer / lever at 2472×3300, 128 spp; dial_safe / combo / disc_detainer / egyptian / time_lock / axial_slider at 1236×1648, 256 spp; magnetic and dimple tools at 48 px/mm, 128 spp. Warded all three passes rerendered together from current materials. Lever includes detector pass.
- End-to-end wall times (seconds): pin 24, warded 56, wafer 47, lever 49, lever detector pass 26, dial_safe 48, combo 21, disc_detainer 15, egyptian 19, time_lock 22, axial_slider 18, tools 2. Detailed evidence: `device-tests/fixes/plates_2x/`.
- Every published game PNG has a forced tracked lossy `.import`, quality 0.85. Measured published-family CTEX sum: see `import-sizes.json`.
- Local resource pack: 56,177,220 bytes without the five-lever candidate; 58,142,664 with it. The detector candidate is kept outside `game/` under `art/renders/lever_detector/` because the latter exceeds the 58 MB budget. These are resource-size measurements: Windows lacks the lockcore native library, so Godot wrote the pack but returned errors; session A owns authoritative CI confirmation.
- Five-lever candidate: shared canonical layout, deeper case, five springs/rivets/spacers, longer stump, detector on last leaf. Gate dimensions unchanged. GLB required nodes and `rest_lift == need` verified. Gate separation at 412 dp: 39.31, 37.09, 35.05, 33.17 dp. Bake 61 s; photo plates 15 s. GUT / both-mode opening pending session A because this checkout has no Windows lockcore GDExtension.
- Phone: Samsung SM-A165F, 1080×2340. Latest successful Android CI run at download: 42163108394, commit `356acbed`. Existing APK had a different signing key. With explicit owner approval, backed up files/shared_prefs, installed CI APK and restored all 40 regular files with SHA-256 equality. Private backups stay in ignored `build/local-session/phone-backup/`.
- Device testing in progress; evidence under `device-tests/run42163108394-local/`. Existing install was replaced without losing its save. Screenshots describe CI APK, not the new local GPU plate batch.
- Arrival sequences and stills in progress at full settings, local masters under ignored `build/local-session/arrival-master/`. No Magnific D1/D2 cutouts available; shadows/composites remain blocked on those images. Menu final queued after arrival. No marketing work, agents, game logic or CI edits.

## Open coordination items for session A

1. Confirm Linux `perf-budget` and Android build for the plate batch; local Windows pack diagnostics are documented in the plate README.
2. Resolve the detector package budget before copying `art/renders/lever_detector/` into `game/assets/photoreal_families/lever_detector/`; copying the GLB unlocks the family automatically. Then run GUT both-mode opening test and visual projection QA.
3. Review N-67 (quality initialization error) and N-68 (detector pack budget) in `SESSION-B-LOG.md`.
4. Arrival/menu integration remains session A's decision after visual approval. Magnific D1/D2 still required for real-character shadow maps and compositing.


### N-68 update: package budget fits after session A menu changes

After rebasing main with session A's D-62 menu, measured the full resource pack again: 55,833,660 bytes without detector, **57,799,088 bytes including it**, below 58 MB. The same candidate is now integrated into `game/assets/photoreal_families/lever_detector/` with lossy photo imports; the view unlocks it via its existing resource check. No local game code, i18n or CI changes. The authoritative Linux perf-budget and GUT both-mode test remain session A's responsibility (no Windows lockcore GDExtension). Candidate binary duplicates under art are removed; geometry evidence stays there.


### Published GPU batch

Commit `4766aaca` pushed. Authoritative CI perf-budget run 42185136911 succeeded: pck 57.5 MB. Device regression N-69 logged with screenshots; no game code changes.


### Device regression results

Working APK tested across all twelve ready families. Owner confirmed game test pulse absent but system oneshot works (N-70). GPU APK 42185136957 installed successfully but missing menu_layout.json blocks all UI (N-71); restored working APK with install -r and preserved data. game-tests failed, including detector both-mode opening (N-72); session A must resolve logic/tests and missing menu assets. No local game-code/CI fix.


## Final art delivery — 2026-11-06

- Arrival: 108 master frames (3×36), 1080×1920 / 128 spp / hair enabled; four hold images at 1080×1920 / 512 spp, OIDN, camera metadata and depth. Verified dimensions/counts and compared with lock references. Master sequences local only (`build/local-session/arrival-master/`); final sheets/stills under `art/renders/arrival/`.
- Measured wall seconds: night seq 903, evening seq 772, day seq 689; night/evening/day/ajar holds 195/78/68/80. First sequence/hold include kernel compilation.
- Menu: all languages/orientations and pressed states at 160 spp; default close-camera batch 193 s, then portrait camera widened with --vw 600 to 73.89% board width. All portrait hits/sprites rerendered consistently. Current A close frame and requested 75% frame compared in `compare_portrait_framing.jpg`. Menu exported to art only (--no-game).
- Warded: canonical `art/renders/warded.png` rerendered with a ward-only linked key. Minimum of six checked adjacent contrast regions 3.09:1; sampling, grayscale proof, baseline blob and exact parameters under `art/renders/warded_contrast_check/`. Render-only wrapper `art/blender/warded_contrast.py`; camera/materials/geometry inherited from original warded scene. A brighter whole-scene key failed to separate the plate patina reliably, hence the linked readability light.
- Ring combo: not rerendered; session A's latest handoff says the digit correction is already complete, rerender only for a future 2× art requirement.
- Owner confirmed normal spoken dialogue in PL and EN. System language and free device rotation restored; media volume unchanged (13/15).
- Session A has landed fixes for N-67/N-69/N-70/N-71 and reports N-72 detector both-mode opening fixed (assets are correct; no rerender). Retest awaits a successful Android artifact containing those fixes. Physical full S1–S3/two-thumb and H0–H4 signoff remains open.
- No new Magnific D1/D2 supplied: no final character shadow maps/composites. Existing placeholders and CPU shadow proofs remain explicitly marked previews. Arrival/menu integration belongs to session A after visual approval.


## 2026-11-07 — Local Windows build and test runs (lockcore GDExtension)

The Windows checkout can now load lockcore, so headless import, `lock_test`, smoke and the full GUT suite run locally.

- Toolchain (one-time, per-user, no admin): `winget install -e --id MartinStorsjo.LLVM-MinGW.UCRT` (clang 23, UCRT) and `python -m pip install --user scons`. godot-cpp is cloned by the script at the CI-pinned commit `e103d348` (N-28) into `C:\tools\godot-cpp-e103d34`.
- `lockcore_gd.gdextension` now lists `windows.debug.x86_64` / `windows.release.x86_64` (`bin/liblockcore_gd.windows.template_{debug,release}.dll`); `SConstruct` names Windows output `.dll`. The DLLs stay untracked (`game/addons/lockcore_gd/bin/` is gitignored); CI is unchanged and keeps building its own Linux/Android libraries.
- Build: `tools/local/win_build_lockcore.sh` (both targets, about 1 min each cold; `debug` or `release` for one). The DLL links the C++ runtime statically and imports only Windows UCRT/KERNEL32.
- Test: `tools/local/run_gut.sh` = import + `lock_test` + smoke + full GUT (same args as game-tests.yml). Options: `--skip-import`, `--gut-only`, `-- -gselect=test_save` (extra GUT args), `--screens` (game-screens capture via opengl3 — uses the GPU, keep it off while rendering). Logs go to `qa/out/local/`. Godot path: `GODOT` env, default `C:\tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe`.
- Result on this PC: lock_test ok, smoke ok, GUT 249/249 tests passing. The first run had 248/249: `test_voice_packs::test_offline_and_http_error_stay_subtitle_only`. Cause: Godot 4.7.2 on Windows never reports a refused loopback connect. `HTTPClient` stays `STATUS_CONNECTING`, so the game falls back to its 20 s "timeout" instead of "offline". The "offline" leg of that test is now skipped on Windows only; the HTTP 404 leg still runs. Not a mobile bug.
- Local import noise: it rewrites tracked `*.import` files with LF line endings (autocrlf only, no content change) and regenerates the tracked `game/i18n/*.translation`. Do not commit them. Stage only intentional files.
- Not covered locally: `--export-debug "Linux"` pck needs the Linux `.so`. Use CI export-pack-test for that, or add a Windows preset later.
