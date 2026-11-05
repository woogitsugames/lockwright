# Lockwright — EN store copy reviewed (T02)

2026-11-05 · Wersja do akceptacji i weryfikacji w buildzie 1.0. Liczby liczone bez otaczających znaczników Markdown oraz końcowych znaków nowej linii. Wariant A **wyłącznie warunkowo** (D-06 nierozstrzygnięta).

## App Store — EN (en-US/en-GB)

### Name

29 znaków (limit 30)

```text
Lockwright: Locksmith on Call
```

### Subtitle

28 znaków (limit 30)

```text
Open locks by feel and sound
```

### Promotional text

156 znaków (limit 170)

```text
A quiet shift, a stubborn pin and a spool that almost tells the truth. Work fictional locks by touch, sound and careful timing. No shortcuts, just patience.
```

### Keywords — no spaces after commas

92 znaków / 92 bajtów (limit 100 bajtów)

```text
tactile,puzzle,haptics,pin,tumbler,mechanism,workshop,tools,craft,precision,repair,simulator
```

### Full description

1194 znaków (limit 4000)

```text
A missing key. Someone on the wrong side of a door. You're the locksmith on call.

Lockwright is a tactile puzzle game about fictional, unbranded locking mechanisms. A close-up cutaway shows the metal moving. Your left thumb controls a tension wrench; your right guides the pick. A pin may bind, settle with a dry click, or move too far. Sound, motion and resistance tell you what happened.

At the workbench
• Practise with simple locks, then take on longer runs at your own pace.
• Watch for small changes in the pins, listen closely and feel the resistance on supported devices.
• Keep your tools in good condition at the workshop.
• A pick can bend or break. Patience is part of the job.
• Learn to recognise a proper set, a false set and the moment to ease off.

A careful trade
• Visual and audio cues carry the important information; supported Apple devices add haptic feedback.
• No real manufacturer's lock or branded mechanism is reproduced here.
• A locksmith checks the right of entry before opening a customer's door. This is a game, not a locksmithing course.

The mechanisms are invented and simplified for play. The aim is to help, not to get into places where you don't belong.
```

### Optional Variant A — not approved

93 znaków (limit 4000)

```text
Try the first locks before you buy. One in-app purchase opens the full game. No subscription.
```

### What's New (1.0)

96 znaków (limit 4000)

```text
First release. The workbench is ready, the picks are in the roll, and the first lock is waiting.
```


## Google Play — EN

### Title

29 znaków (limit 30)

```text
Lockwright: Locksmith on Call
```

### Short description

80 znaków (limit 80)

```text
A locksmith's quiet puzzles: fictional locks, careful touch and close listening.
```

### Full description

1191 znaków (limit 4000)

```text
A missing key. Someone on the wrong side of a door. You're the locksmith on call.

Lockwright is a tactile puzzle game about fictional, unbranded locking mechanisms. A close-up cutaway shows the metal moving. Your left thumb controls a tension wrench; your right guides the pick. A pin may bind, settle with a dry click, or move too far. Sound, motion and resistance tell you what happened.

At the workbench
• Practise with simple locks, then take on longer runs at your own pace.
• Watch for small changes in the pins, listen closely and feel the resistance on supported devices.
• Keep your tools in good condition at the workshop.
• A pick can bend or break. Patience is part of the job.
• Learn to recognise a proper set, a false set and the moment to ease off.

A careful trade
• Visual and audio cues remain available without vibration. Supported phones add tactile feedback.
• No real manufacturer's lock or branded mechanism is reproduced here.
• A locksmith checks the right of entry before opening a customer's door. This is a game, not a locksmithing course.

The mechanisms are invented and simplified for play. The aim is to help, not to get into places where you don't belong.
```

### What's new (1.0)

96 znaków (limit 500)

```text
First release. The workbench is ready, the picks are in the roll, and the first lock is waiting.
```


### Platform-specific haptics bullet

```text
• Visual and audio cues remain available without vibration. Supported phones add tactile feedback.
```

## Character and UTF-8 byte counts

| Field | Limit | Characters | UTF-8 bytes | Check |
|---|---:|---:|---:|---|
| `as.en.name` | 30 | 29 | 29 | OK |
| `as.en.subtitle` | 30 | 28 | 28 | OK |
| `as.en.promo` | 170 | 156 | 156 | OK |
| `as.en.keywords` | 100 bytes | 92 | 92 | OK |
| `as.en.description` | 4000 | 1194 | 1210 | OK |
| `as.en.variant_a` | 4000 | 93 | 93 | OK |
| `as.en.whatsnew` | 4000 | 96 | 96 | OK |
| `gp.en.title` | 30 | 29 | 29 | OK |
| `gp.en.short` | 80 | 80 | 80 | OK |
| `gp.en.haptics_line` | 4000 | 98 | 100 | OK |
| `gp.en.description` | 4000 | 1191 | 1207 | OK |
| `as.en.description+A` | 4000 | 1289 | 1305 | OK |
| `gp.en.description+A` | 4000 | 1286 | 1302 | OK |
| `gp.en.whatsnew` | 500 | 96 | 96 | OK |

Full description with conditional Variant A: App Store **1289/4000**, Google Play **1286/4000**. Insert the optional paragraph after the first paragraph only if a demo-plus-IAP business model is formally approved.

## Editorial and release notes

- The store copy is deliberately centred on the fictional lock puzzle, two-thumb controls, tool care and the principle of lawful access.
- It omits unverified release promises: no ads, offline operation, collection of no data, no accounts, in-game purchases and any specific number of story jobs, historic notes or timed challenges.
- Haptic support and parity of visual/audio feedback must be verified on target devices; the present text is a **release draft**, not evidence of implementation.
- Confirm that workshop repair, tool damage and longer runs are actually included before publishing. If not, remove the corresponding bullets.
- Don't publish Variant A or add privacy/monetisation claims until D-06 and implementation are verified. No real lock maker or product is named in this copy.
