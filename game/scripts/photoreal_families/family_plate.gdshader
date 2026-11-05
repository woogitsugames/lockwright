// Lockwright photoreal lock families (Plan B, D-31 / D-37): static parts draw the Cycles render
// of the static scene projected through the fixed camera, with real-time contact occlusion.
shader_type spatial;
render_mode unshaded, shadows_disabled, ambient_light_disabled, fog_disabled;

uniform sampler2D plate : source_color, filter_linear, repeat_disable;
uniform float exposure = 1.0;
#include "res://scripts/photoreal_families/family_occlusion.gdshaderinc"
varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	ALBEDO = texture(plate, SCREEN_UV).rgb * family_stack_shade(world_pos) * exposure;
}
