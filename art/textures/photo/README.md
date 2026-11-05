# Photo materials (Magnific AI, D-42 / D-48)

Game-ready maps built from the photos selected by session A
(`contrib/incoming/magnific/selected/`, `contrib/incoming/leather_set_2026-11-05/`).
Everything here is produced by **`tools/make_photo_materials.py`** — rerun it instead of editing files:

```bash
pip install numpy pillow opencv-python-headless
nice -n 10 python3 tools/make_photo_materials.py            # all
nice -n 10 python3 tools/make_photo_materials.py cement_tiles thumb_dent   # selected ones
```

Check sheets: `contact_previews.jpg` (all 2×2 tiling previews), `contact_objects.jpg` (cut-outs on a checker).

## Files per surface (`<name>/`)

| File | Content |
|---|---|
| `<name>_albedo.jpg` / `_albedo_1k.jpg` | sRGB colour, lighting gradient removed, 2048² / 1024² (JPG q92) |
| `<name>_normal.png` / `_normal_1k.png` | tangent-space normal, **OpenGL convention (+Y / green up)** — Godot's convention, no flip needed |
| `<name>_rough.png` / `_rough_1k.png` | linear roughness, 8-bit grey; metals clamped ≥ 0.16 (no chrome, `docs/styles/realizm.md`) |
| `<name>_height_1k.png` | 16-bit height (luminance high-pass, 0.5 = mean), for parallax/displacement or re-deriving normals |
| `<name>_preview_2x2.jpg` | seam check: left 2×2 albedo, right 2×2 shaded normal (not a game asset) |
| `material.json` | tiling mode, metallic, roughness range, normal strength, seam overlaps, source file |

Pipeline: (1) per-channel 2nd-order polynomial + large-radius luminance division removes the light fall-off
and tint drift, mean colour kept; fine-detail contrast equalised; `leather_brown_new` also gets a keystone
fix (its grain was 1.6× finer at the top because of camera tilt); (2) seamless via best-match overlap + minimum-error
boundary cut (image quilting) with a 3 px feather, per axis, then resampled to 2048²; (3) height/normal/roughness
derived from the tiled albedo with wrap-around filters, so all maps tile identically; (4) 1024² copies.
Special cases: `pine_floor_painted` / `bench_beech_top` / `wall_paint_divider_line` are deskewed so plank gaps
or the divider line are exactly axis-aligned; `pegboard_brown` is tiled on the measured hole pitch;
`steel_heat_tint` uses a wide crossfade (smooth gradient, a cut would show); `brass_turned` has the angular
highlight “bow-tie” divided out in polar space. Normals above 10 MB as PNG are softened by ≤ 0.6 px
(`normal_2k_soften_sigma` in `material.json`).

Roughness is a heuristic (inverted local contrast + a little inverted luminance), not a scan —
tune `roughness_range` in the script, not by painting the maps.

## Surfaces and intended use

| Name | Tiling | Metal | Use |
|---|---|---|---|
| `leather_brown_new` | u+v | no | tool-roll HUD (new roll), straps |
| `leather_brown_worn` | u+v | no | tool-roll HUD (worn roll, later chapters), workshop apron |
| `leather_chocolate` | u+v | no | dark leather variant: tool-roll lining, case for showcase items (source: Nano Banana leather set, not Magnific) |
| `leather_stitching_strip` | u only | no | tool-roll edge / pocket seams: map along a strip UV, V spans the band with two stitch rows |
| `brass_turned` | none, centred | yes | lock plug face (radial turning marks centred on the plug axis), knob rosettes |
| `brass_face_milled` | u+v | yes | lock faceplate / forend, lever-lock case front |
| `brass_patina_grease` | u+v | yes | old lock chassis, internal brass parts, greasy wards |
| `steel_ground` | u+v | yes | chassis plates, tension tools, levers (ground finish) |
| `steel_heat_tint` | u only | yes | springs / tempered parts: U along the part, V = gold→blue temper band |
| `spring_steel_polished` | u+v | yes | picks, springs, shims (roughness 0.16–0.28) |
| `nickel_satin` | u+v | yes | cylinder housing, escutcheons, modern hardware |
| `iron_painted_rust` | u+v | no (painted) | old doors, gates, cellar hardware; treat as dielectric paint |
| `terrazzo_grey_red` | u+v | no | stairwell floor (block of flats) |
| `cement_tiles` | u+v | no | hallway / kiosk floor (patterned cement tiles, ~4×4 tiles per repeat) |
| `pine_floor_painted` | u+v | no | apartment / attic floor (painted pine planks) |
| `workshop_concrete` | u+v | no | workshop and cellar floor |
| `bench_beech_top` | u+v | no | workbench top (butcher-block beech), lock-screen backdrop in the workshop |
| `wall_lime_plaster` | u+v | no | old lime-plaster walls: stairwell, cellar, attic |
| `wall_oil_paint_green` | u+v | no | oil-painted lower wall (dado) of the stairwell |
| `wall_paint_divider_line` | u only | no | stairwell wall with the painted divider line (plaster above, green oil paint below); 2048×1616, keep aspect |
| `pegboard_brown` | u+v | no | workshop tool wall; tiled on the hole pitch (19×19 holes per repeat, grid stays regular across seams) |
| `steel_cast_grey_paint` | u+v | no (painted) | painted cast lock cases, old machine parts (grey-green paint) |
| `velvet_display_green` | u+v | no | showcase / exhibit display cloth (needs a sheen term in the shader) |
| `glass_cabinet_dust` | u+v | — | **overlay, not PBR**: `_mask.png` grayscale (white = dust/fingerprints) for showcase glass opacity/roughness |

Notes from the seam check (see `contact_previews.jpg`): photos with one strong hero feature
(`brass_patina_grease` blotches, `iron_painted_rust` rust edge, `workshop_concrete` stains, `glass_cabinet_dust`
fingerprints) repeat visibly at 2×2 — use them at large UV scale or on single parts, or break up with decals.
`brass_face_milled` was rotated so the milling bands are horizontal (rotate the UV ~42° for the original
diagonal look) and straightened per column; small steps remain where bands of uneven width meet.
`iron_painted_rust` uses only the sharp upper-left 66 % of the photo (the rest is out of focus).
`spring_steel_polished`: the photo has a band of stronger brush marks, so the normal shows a faint band at
2×2 (albedo is clean); keep its normal strength low. `paper_note_torn` / `paper_receipt_pad` keep their
perforation holes transparent.

## Objects (`objects/`)

RGBA PNG cut-outs (full-res crop + `_1k` copy, longest side 1024). GrabCut initialised with a rect from the script
(photo backgrounds were plain or near plain); edges feathered ~1 px. Shadows are cut away — add them in-engine.

| File | Use |
|---|---|
| `tool_roll_open_empty.png` | tool-roll HUD background (open roll, empty pockets) |
| `tool_roll_pocket_empty_closeup.png` | single pocket close-up for the HUD slot / zoom |
| `leather_brass_snap.png` | brass snap of the roll (round cut, Hough circle) |
| `thumb_dent.png` + `thumb_dent_normal.png` | decal: thumb dent in leather with soft radial alpha; normal decal for the leather material |
| `coconut_doormat.png` | doorstep prop (arrival screen) |
| `envelope_front.png`, `envelope_back.png` | paper props: job letters |
| `paper_card_stock.png`, `paper_note_torn.png`, `paper_office_folded.png`, `paper_receipt_pad.png` | paper props: job cards, notes, receipts, documents proving the right to the premises |
| `ink_oval_blank.png` | stamp ink oval (alpha from ink density, blank inside — text is added by the game via i18n) |
| `icon_doorbell.png`, `icon_enamel_L.png`, `icon_number_plate_7.png` | icon direction (enamel plate "L"), doorbell / number plate props |

Source and licence: AI-generated (Magnific; `leather_chocolate` and `thumb_dent` from Gemini Nano Banana), D-42,
entries in `docs/ASSETS.md`.
