// Contact occlusion of moving lock elements on the static Cycles plate (Plan B, D-31 / D-34).
// stacks[i] = (center_x, bottom_y, top_y, active_radius); world units = mm (Godot y = Blender z).
uniform vec4 stacks[5];
uniform float occ_strength = 0.58;
uniform float spring_occ = 0.55;
uniform float cap_y = 6.2;
uniform float shear_y = -999.0;     // optional horizontal shear line y for extra dark gap (T06 #4)
uniform float shear_half_w = 0.22;  // half-width of the dark shear gap in mm (>= 2 dp)

float family_stack_shade(vec3 wp) {
	float shade = 1.0;
	for (int i = 0; i < 5; i++) {
		vec4 s = stacks[i];
		if (s.w <= 0.01) {
			continue;
		}
		float r = s.w;
		float d = abs(wp.x - s.x);
		float radial = 1.0 - smoothstep(r * 0.65, r * 1.35, d);
		float elem = smoothstep(s.y - 0.5, s.y + 0.5, wp.y) * (1.0 - smoothstep(s.z - 0.4, s.z + 0.5, wp.y));
		float spr = 0.0;
		if (cap_y > s.z + 0.2) {
			spr = smoothstep(s.z - 0.2, s.z + 0.5, wp.y) * (1.0 - smoothstep(cap_y - 0.3, cap_y + 0.3, wp.y));
		}
		shade *= 1.0 - radial * (occ_strength * elem + spring_occ * spr);
	}
	if (shear_y > -900.0) {
		float dy = abs(wp.y - shear_y);
		float s_gap = 1.0 - smoothstep(shear_half_w * 0.4, shear_half_w * 1.4, dy);
		shade *= 1.0 - 0.52 * s_gap;
	}
	return clamp(shade, 0.12, 1.0);
}
