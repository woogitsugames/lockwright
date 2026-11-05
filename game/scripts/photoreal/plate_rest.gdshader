// Plan B for parts that are in the Cycles plate but move a little (plug, tension wrench): the plate
// is projected from the part's REST pose, so the picture travels with the geometry when it rotates.
// Valid for small motions only (the plug turns a few degrees while picking).
shader_type spatial;
render_mode unshaded, shadows_disabled, ambient_light_disabled, fog_disabled;

uniform sampler2D plate : source_color, filter_linear, repeat_disable;
uniform mat4 rest_model = mat4(1.0);  // the part's world transform at rest (Cycles pose)
uniform float exposure = 1.0;
varying vec4 rest_clip;

void vertex() {
	rest_clip = PROJECTION_MATRIX * VIEW_MATRIX * rest_model * vec4(VERTEX, 1.0);
}

void fragment() {
	vec2 uv = rest_clip.xy / rest_clip.w * 0.5 + 0.5;
	uv.y = 1.0 - uv.y;
	ALBEDO = texture(plate, uv).rgb * exposure;
}
