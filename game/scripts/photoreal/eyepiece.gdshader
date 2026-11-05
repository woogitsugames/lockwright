shader_type canvas_item;
// Eyepiece field (N-57): round mask over a magnified region of the 3D section texture.
uniform vec2 centre_uv = vec2(0.5);
uniform vec2 half_uv = vec2(0.1);
uniform float iris = 1.0;

void fragment() {
	vec2 d = UV - vec2(0.5);
	float r = length(d) * 2.0;
	if (r > iris) {
		discard;
	}
	vec4 c = texture(TEXTURE, centre_uv + d * 2.0 * half_uv);
	// vignette at the edge of the field (a lens barrel, not a glow)
	float v = 1.0 - smoothstep(iris * 0.78, iris, r) * 0.55;
	COLOR = vec4(c.rgb * v, 1.0);
}
