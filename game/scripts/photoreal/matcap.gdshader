// Plan B, moving parts (pins, springs, pick): lit sphere (matcap) rendered in Cycles under the same
// lights and seen along the scene camera, plus the part's baked normal map and AO (spikes/lit-metal).
// Optional bend: the pick shaft bows under tool stress (HUD.md §3), as a vertex offset.
shader_type spatial;
render_mode unshaded, shadows_disabled, ambient_light_disabled, fog_disabled;

uniform sampler2D matcap : source_color, filter_linear, repeat_disable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap;
uniform sampler2D orm : hint_default_white, filter_linear_mipmap;
uniform float normal_strength = 1.0;
uniform float exposure = 1.0;
uniform float bend = 0.0;              // mm, downward bow of the shaft
uniform vec2 bend_span = vec2(-46.0, 9.0);  // object-space x range that bows (handle end .. hook)

void vertex() {
	if (bend != 0.0) {
		float t = clamp((VERTEX.x - bend_span.x) / (bend_span.y - bend_span.x), 0.0, 1.0);
		VERTEX.y -= bend * sin(3.14159265 * t);
	}
}

void fragment() {
	vec2 nxy = (texture(normal_map, UV).xy * 2.0 - 1.0) * normal_strength;
	vec3 tn = vec3(nxy, sqrt(max(0.0, 1.0 - dot(nxy, nxy))));
	vec3 n = normalize(TANGENT * tn.x + BINORMAL * tn.y + NORMAL * tn.z);
	vec2 muv = vec2(n.x, -n.y) * 0.49 + 0.5;
	float ao = mix(1.0, texture(orm, UV).r, 0.6);
	ALBEDO = texture(matcap, muv).rgb * ao * exposure;
}
