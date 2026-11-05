#!/usr/bin/env python3
"""Generate game/THIRD-PARTY-NOTICES.txt (task 13). Deterministic; CI checks it is up to date."""
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "game", "THIRD-PARTY-NOTICES.txt")

NOTICES = """THIRD-PARTY NOTICES — Lockwright: Locksmith on Call
====================================================

This file lists the third-party components shipped in the app. Full license texts
follow each entry. Game code, art and audio are original project assets (see
docs/ASSETS.md for provenance of every asset).

1. Godot Engine 4.7.2 — MIT License
   Copyright (c) 2014-present Godot Engine contributors.
   Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.
   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:
   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.
   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.

2. godot-cpp (GDExtension bindings, lockcore_gd / LockwrightHaptics) — MIT License
   Copyright (c) 2017-present Godot Engine contributors.
   Same MIT text as above (https://github.com/godotengine/godot-cpp).

3. GUT — Gut Unit Test (test framework, addons/gut, test builds only) — MIT License
   Copyright (c) 2020-present Tom "Butch" Wesley.
   Same MIT text as above (https://github.com/bitwes/Gut).

4. Oboe (low-latency audio, statically linked in the Android click-audio plugin)
   — Apache License 2.0
   Copyright 2019-2024 Google LLC.
   Licensed under the Apache License, Version 2.0 (the "License"); you may not
   use this file except in compliance with the License. You may obtain a copy of
   the License at http://www.apache.org/licenses/LICENSE-2.0
   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
   WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

5. Fonts (SIL Open Font License 1.1, full texts in game/assets/fonts/OFL-*.txt)
   - Bona Nova (font by Katarzyna Mroczkowska / TipoType) — SIL OFL 1.1
   - Atkinson Hyperlegible Next (Braille Institute) — SIL OFL 1.1

Engine components bundled by Godot (FreeType — FTL, mbedTLS — Apache-2.0,
ICU — ICU license, etc.) are listed at runtime via Engine.get_copyright_info().
"""

with open(OUT, "w", encoding="utf-8") as f:
    f.write(NOTICES)
print("wrote", OUT)
