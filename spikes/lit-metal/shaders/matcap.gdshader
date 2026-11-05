// Plan B, moving parts: lit-sphere (matcap) rendered in Cycles under the same lights and seen
// along the scene camera, plus the baked normal map and AO of the part. Unshaded, one texture fetch
// per map, no light loop.
shader_type spatial;
render_mode unshaded, shadows_disabled, ambient_light_disabled, fog_disabled;

uniform sampler2D matcap : source_color, filter_linear, repeat_disable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap;
uniform sampler2D orm : hint_default_white, filter_linear_mipmap;
uniform float normal_strength = 1.0;

void fragment() {
	vec3 n = NORMAL;
	// Normal maps are imported as two-channel (RG) VRAM textures: rebuild Z.
	vec2 nxy = (texture(normal_map, UV).xy * 2.0 - 1.0) * normal_strength;
	vec3 tn = vec3(nxy, sqrt(max(0.0, 1.0 - dot(nxy, nxy))));
	n = normalize(TANGENT * tn.x + BINORMAL * tn.y + NORMAL * tn.z);
	vec2 muv = vec2(n.x, -n.y) * 0.49 + 0.5;
	float ao = mix(1.0, texture(orm, UV).r, 0.6);
	ALBEDO = texture(matcap, muv).rgb * ao;
}
