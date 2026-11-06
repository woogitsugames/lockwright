"""Canonical five-lever detector layout shared by look-dev and baked plates."""


def detector_levers():
    # Six mm between leaves exposes each gate face at the oblique game camera.
    needs = (3.5, 2.5, 3.0, 4.0, 2.8)
    bellies = (-11.2, -12.0, -11.6, -11.0, -12.2)
    return [(0.9 + 6.0 * i, need, need, bellies[i]) for i, need in enumerate(needs)]
