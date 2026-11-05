shader_type canvas_item;
// N-54: darkens the photo where the menu plates sit (lower part + edges), so cream
// text and enamel plates keep >= 4.5:1. Flat warm-black, no colour gradients.
uniform vec4 tint : source_color = vec4(0.05, 0.035, 0.025, 1.0);
uniform float base = 0.18;
uniform float lower = 0.55;
uniform float edge = 0.45;
uniform float split = 0.38; // where the darkening starts (0 = top)
uniform bool landscape = false;

void fragment() {
	float t = landscape ? smoothstep(split, 0.95, UV.x) : smoothstep(split, 0.85, UV.y);
	vec2 c = (UV - vec2(0.5)) * vec2(1.1, 1.0);
	float v = smoothstep(0.35, 0.8, length(c));
	COLOR = vec4(tint.rgb, clamp(base + lower * t + edge * v, 0.0, 0.88));
}
