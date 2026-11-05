// Contact occlusion of the moving pin stacks on the static plate (the plate is rendered without
// them, D-34): darkens chamber walls behind pins and springs, analytic and per stack.
// stacks[i] = (axis x, key-pin bottom y, driver top y, active 0/1); world units = mm.
uniform vec4 stacks[5];
uniform float pin_occ = 0.6;     // darkening behind key pins and drivers
uniform float spring_occ = 0.62;  // behind the springs (driver top .. cap)
uniform float cap_y = 21.6;

float stack_shade(vec3 wp) {
	float shade = 1.0;
	for (int i = 0; i < 5; i++) {
		vec4 s = stacks[i];
		if (s.w < 0.5) {
			continue;
		}
		float d = length(vec2(wp.x - s.x, wp.z));
		float radial = 1.0 - smoothstep(1.45, 2.4, d);
		float pins = smoothstep(s.y - 0.4, s.y + 0.4, wp.y) * (1.0 - smoothstep(s.z - 0.3, s.z + 0.5, wp.y));
		float spring = smoothstep(s.z - 0.2, s.z + 0.6, wp.y) * (1.0 - smoothstep(cap_y - 0.4, cap_y + 0.2, wp.y));
		shade *= 1.0 - radial * (pin_occ * pins + spring_occ * spring);
	}
	return shade;
}
