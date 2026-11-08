"""Canonical five-lever detector layout shared by look-dev and baked plates."""

# N-87 (2026-11-08): the five-leaf pack is 26 mm deep, so the 3-lever camera (target x 1, 160 mm) cut the
# pivot and the levers' tails off on the left (pivot x = -22 mm outside the frame). Target shifted 7.3 mm
# towards the pivot and the camera pulled back to 190 mm: the whole pack, pivot post and the case's rear
# wall are in the 3:4 frame with >= 60 px (of 1236) to spare on both sides. Same yaw/pitch/lens.
DETECTOR_CAMERA = {'tx': -6.3, 'tz': -2.0, 'dist': 190.0}


def detector_levers():
    # Six mm between leaves exposes each gate face at the oblique game camera.
    needs = (3.5, 2.5, 3.0, 4.0, 2.8)
    bellies = (-11.2, -12.0, -11.6, -11.0, -12.2)
    return [(0.9 + 6.0 * i, need, need, bellies[i]) for i, need in enumerate(needs)]
