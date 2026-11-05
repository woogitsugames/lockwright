shader_type canvas_item;
// N-54: light vignette over the menu photo. Darkens the title band (top), the
// footer (bottom) and the edges so cream text keeps >= 4.5:1, and leaves the
// middle (where the enamel plates hang) bright. Flat warm-black, no colour gradients.
uniform vec4 tint : source_color = vec4(0.05, 0.035, 0.025, 1.0);
uniform float base = 0.08;
uniform float top_strength = 0.55;
uniform float top_end = 0.3;      // top band fades out by this UV.y
uniform float lower_start = 0.78; // footer band starts here
uniform float lower_strength = 0.45;
uniform float edge = 0.3;
uniform bool landscape = false;   // landscape: darken the left (title) side instead of the top

void fragment() {
	float a = landscape ? UV.x : UV.y;
	float t = (1.0 - smoothstep(0.0, top_end, a)) * top_strength;
	float l = smoothstep(lower_start, 1.0, UV.y) * lower_strength;
	vec2 c = (UV - vec2(0.5)) * vec2(1.1, 1.0);
	float v = smoothstep(0.4, 0.85, length(c)) * edge;
	COLOR = vec4(tint.rgb, clamp(base + t + l + v, 0.0, 0.85));
}
