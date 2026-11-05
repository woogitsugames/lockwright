// Lockwright photoreal lock screen (plan B, D-31): static parts draw the Cycles render of the
// static scene, projected through the fixed camera. Real depth, zero lights, zero probes.
shader_type spatial;
render_mode unshaded, shadows_disabled, ambient_light_disabled, fog_disabled;

uniform sampler2D plate : source_color, filter_linear, repeat_disable;
uniform float exposure = 1.0;

void fragment() {
	ALBEDO = texture(plate, SCREEN_UV).rgb * exposure;
}
