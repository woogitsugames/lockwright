# Android device test — 2026-11-06

Device: Samsung SM-A165F, 1080×2340. APK CI run 42163108394, commit 356acbed. Screenshots in this directory are this working APK unless explicitly moved to the GPU APK directory.

## Observed

- Boot, settings, job list, Polish dialogue arrival, verification, lock screen, pause flap, resume/exit, populated receipt and Back from receipt to job list.
- Plan B screens loaded through the job list: pin_tumbler, warded, wafer, lever, dial_safe, combo, magnetic, dimple, disc_detainer, egyptian, axial_slider, time_lock. This confirms screen entry and appearance, not successful manual opening in both control modes.
- Dial safe landscape captured. Device rotation temporarily locked during testing; return to free rotation after tests.
- A 60-second screen recording covers dimple, navigation and dial safe. Full recording remains locally in ignored `build/local-session/phone-test.mp4`; `contact.png` samples the full minute.
- Receipt after wafer showed client, service, 85-coin reward, 21-coin tip and 106 total. Android Back completed the receipt and returned to jobs.
- N-67: quality autoload add_child error at boot, then automatic medium profile. N-69: Android Back did not open pause on wafer/warded/magnetic, while flap did; it worked from settings and payment.
- N-70: owner reported no physical vibration from the game's test pulse (enabled, intensity 100%), but confirmed an independent system oneshot 250 ms. The motor/system works; app haptics require session A investigation. Native singleton was detected but the facade reported fallback/native=false.

## Limits and handoff

Full S1–S3 and two-thumb input validation, H0–H4 timing/ghost quality are not signed off. PL and EN spoken dialogue were both confirmed audible in the correct language by the owner; screenshots `pl-voice-check.png` and `en-voice-check.png`. Audio playback and tactile quality require physical confirmation; the vibration comparison above was confirmed by the owner. GPU detector device testing was blocked by the new APK's missing menu assets; see `../run42185136957-local/`.

Original application data was backed up before the owner-approved signature-changing reinstall and all 40 files restored with matching SHA-256. Private backups are not committed. Updating to the GPU APK and restoring the working APK both used install -r without clearing data.

The phone was returned to system language (Polish) and free rotation. System media volume was read as 13/15 and left unchanged.
