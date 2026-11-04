// Plan B, static parts: the Cycles render of the static scene, projected through the camera.
// Every static mesh draws exactly the Cycles pixel under it, so depth stays real and the
// moving parts are correctly hidden behind chamber walls. Unshaded: zero lights, zero probes.
shader_type spatial;
render_mode unshaded, shadows_disabled, ambient_light_disabled, fog_disabled;

uniform sampler2D plate : source_color, filter_linear, repeat_disable;

void fragment() {
	ALBEDO = texture(plate, SCREEN_UV).rgb;
}
