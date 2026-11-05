shader_type canvas_item;
render_mode blend_mul;
// D-59 combo: the digit band of one thumbwheel wrapped on a cylinder (axis horizontal) and multiplied
// over the blank, Cycles-lit wheel of the plate. The sprite covers the upper half of the wheel: UV.y = 1
// at the axis (front of the wheel, 0°), 0 at the top (90°). Digits increase downwards on the band, so
// rolling the wheel up brings the next digit to the reading line.
uniform sampler2D band : filter_linear_mipmap, repeat_enable;
uniform float pos = 0.0;          // wheel position, fraction of a turn (digit = pos * 10)
uniform float read_a = 0.5236;    // reading line, radians above the front
uniform float u_scale = 1.27;     // wheel width / band width
uniform float dim = 1.0;          // "in the dark"

void fragment() {
	float h = clamp(1.0 - UV.y, 0.0, 1.0);
	float a = asin(h);
	float v = pos + 0.05 - (a - read_a) / 6.2831853;
	float u = 0.5 + (UV.x - 0.5) * u_scale;
	vec3 c = texture(band, vec2(clamp(u, 0.02, 0.98), v)).rgb;
	// the engraving fades towards the silhouette (grazing view), never below the paint
	c = mix(vec3(1.0), c, smoothstep(0.995, 0.85, h));
	COLOR = vec4(c * dim, 1.0);
}
