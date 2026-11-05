#!/bin/sh
# Renders every look-dev shot used by mockups/realizm. 4K masters, ~60-90 min on 4 CPU cores.
cd "$(dirname "$0")/../.."
B=${BLENDER:-/opt/tools/blender-4.2.9-linux-x64/blender}
$B -b -P art/blender/cutaway.py -- --out art/renders/section.png --res 2160x2880 --samples 256 || exit 1
$B -b -P art/blender/tray.py -- --out art/renders/tray.png --res 2160x864 --samples 192 || exit 1
$B -b -P art/blender/cutaway.py -- --shot loupe --out art/renders/loupe.png --res 2160x2160 --samples 256 || exit 1
$B -b -P art/blender/cutaway.py -- --shot microscope --out art/renders/microscope_view.png --res 2160x2160 --samples 160 || exit 1
$B -b -P art/blender/cutaway.py -- --shot borescope --out art/renders/borescope_view.png --res 2160x2160 --samples 128 || exit 1
$B -b -P art/blender/optics.py -- --obj microscope --out art/renders/microscope.png --res 2160x2880 --samples 128 || exit 1
$B -b -P art/blender/optics.py -- --obj borescope --out art/renders/borescope.png --res 2160x2880 --samples 128 --screen art/renders/borescope_view.png || exit 1
echo ALL-DONE
