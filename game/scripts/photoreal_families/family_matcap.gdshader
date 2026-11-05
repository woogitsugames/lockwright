// Plan B moving parts shader for photoreal lock families (wafer, lever, warded, wooden_pin):
// Combines Cycles matcap sphere with baked normal map, ORM (AO + roughness), and optional baked
// albedo grain detail (for wood rings on wooden_pin and forged iron patina on warded).
shader_type spatial;
render_mode unshaded, shadows_disabled, ambient_light_disabled, fog_disabled;

uniform sampler2D matcap : source_color, filter_linear, repeat_disable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap;
uniform sampler2D orm : hint_default_white, filter_linear_mipmap;
uniform sampler2D albedo_map : source_color, hint_default_white, filter_linear_mipmap;
uniform float normal_strength = 1.0;
uniform float albedo_mix = 0.22;       // blends baked wood/patina grain detail into matcap
uniform vec3 tint = vec3(1.0);
uniform float exposure = 1.0;
uniform float bend = 0.0;              // mm, shaft bow under tool stress (HUD.md §3)
uniform vec2 bend_span = vec2(-46.0, 9.0);

void vertex() {
	if (bend != 0.0) {
		float t = clamp((VERTEX.x - bend_span.x) / max(bend_span.y - bend_span.x, 0.001), 0.0, 1.0);
		VERTEX.y -= bend * sin(3.14159265 * t);
	}
}

void fragment() {
	vec2 nxy = (texture(normal_map, UV).xy * 2.0 - 1.0) * normal_strength;
	vec3 tn = vec3(nxy, sqrt(max(0.0, 1.0 - dot(nxy, nxy))));
	vec3 n = normalize(TANGENT * tn.x + BINORMAL * tn.y + NORMAL * tn.z);
	// Stay inside the 0.94 radius of the matcap sphere to avoid grazing rim fringe
	vec2 nm = vec2(n.x, -n.y);
	float l = length(nm);
	nm *= min(l, 0.94) / max(l, 1e-4);
	vec2 muv = nm * 0.49 + 0.5;

	vec3 orm_val = texture(orm, UV).rgb;
	float ao = mix(1.0, orm_val.r, 0.68);
	vec3 mc = texture(matcap, muv).rgb;
	vec3 alb = texture(albedo_map, UV).rgb;
	float alb_luma = dot(alb, vec3(0.2126, 0.7152, 0.0722));
	vec3 grain_mod = mix(vec3(1.0), alb / max(alb_luma, 0.18), albedo_mix * 0.5) * mix(1.0, clamp(alb_luma * 1.65, 0.55, 1.35), albedo_mix);

	ALBEDO = mc * grain_mod * tint * ao * exposure;
}
