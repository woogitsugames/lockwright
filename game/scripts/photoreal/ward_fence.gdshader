// N-63 warded plan B: the lock's ward fences, cut from the Cycles iron slab render (wards.png)
// projected through the fixed camera like the plate. Walls (facing away from the camera) are
// darkened so the fence edge reads as a step (>= 2 dp division line, DESIGN.md).
shader_type spatial;
render_mode unshaded, shadows_disabled, ambient_light_disabled, fog_disabled, cull_disabled;

uniform sampler2D plate : source_color, filter_linear, repeat_disable;
uniform float exposure = 1.0;
uniform float wall_shade = 0.38;

void fragment() {
	float facing = abs(NORMAL.z);  // view space: 1 = top face toward the camera
	float shade = mix(wall_shade, 1.0, smoothstep(0.6, 0.95, facing));
	ALBEDO = texture(plate, SCREEN_UV).rgb * shade * exposure;
}
