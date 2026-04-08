shader_type canvas_item;

// --- [1. Dissolve 및 기본 파라미터] ---
uniform sampler2D noise_tex : repeat_enable;
uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 edge_color : source_color = vec4(1.0, 0.5, 0.1, 1.0);
uniform float edge_thickness : hint_range(0.0, 0.2) = 0.05;
uniform float edge_intensity : hint_range(1.0, 10.0) = 3.0;
uniform float noise_scale : hint_range(0.1, 10.0) = 1.0;

// --- [2. 다중 광원 배열] ---
const int MAX_LIGHTS = 8;
uniform int light_count : hint_range(0, 8) = 0;
uniform vec2 light_directions[8];
uniform vec4 light_colors[8] : source_color;
uniform float light_intensities[8];

uniform float rim_thickness : hint_range(0.0, 20.0) = 5.0;
uniform float rim_softness : hint_range(0.0, 1.0) = 0.5;
uniform float shadow_intensity : hint_range(0.0, 1.0) = 0.3;

// --- [3. 피격 이펙트] ---
uniform vec4 hit_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float hit_strength : hint_range(0.0, 1.0) = 0.0;

// --- [4. 화이트 플래시 효과 (추가됨)] ---
uniform float whiten_strength : hint_range(0.0, 1.0) = 0.0;

// 림 마스크 계산 함수
float get_rim_mask(sampler2D tex, vec2 uv, vec2 p_size, vec2 dir, float thick, float soft, float base_a) {
	if (dot(dir, dir) < 0.01 || thick < 0.1) return 0.0;

	vec2 n_dir = normalize(dir);
	vec2 offset = n_dir * p_size * thick;
	
	float s1 = texture(tex, clamp(uv - offset * 0.5, vec2(0.0), vec2(1.0))).a;
	float s2 = texture(tex, clamp(uv - offset, vec2(0.0), vec2(1.0))).a;
	
	float combined_a = (s1 + s2) * 0.5;
	float diff = max(base_a - combined_a, 0.0);
	return smoothstep(0.0, soft + 0.1, diff);
}

void fragment() {
	// A. 좌표 계산
	vec2 aspect = vec2(1.0 / TEXTURE_PIXEL_SIZE.x, 1.0 / TEXTURE_PIXEL_SIZE.y);
	float m_side = max(aspect.x, aspect.y);
	vec2 n_uv = UV * (aspect / m_side) * noise_scale;

	// B. 기본 색상 및 그림자
	vec4 base_color = texture(TEXTURE, UV);
	vec3 shadow_rgb = base_color.rgb * (1.0 - shadow_intensity);
	
	// C. 다중 광원 루프 연산
	vec3 total_light_rgb = vec3(0.0);
	float max_rim_mask = 0.0;

	for (int i = 0; i < MAX_LIGHTS; i++) {
		if (i >= light_count) break;
		float m = get_rim_mask(TEXTURE, UV, TEXTURE_PIXEL_SIZE, light_directions[i], rim_thickness, rim_softness, base_color.a);
		total_light_rgb += light_colors[i].rgb * light_intensities[i] * m;
		max_rim_mask = max(max_rim_mask, m);
	}

	// D. 색상 합성
	vec3 final_rgb = mix(shadow_rgb, total_light_rgb, clamp(max_rim_mask, 0.0, 1.0));
	
	// 피격 효과 (빨간색 등)
	final_rgb = mix(final_rgb, hit_color.rgb, hit_strength * hit_color.a);
	
	// 화이트 플래시 효과 (하얀색으로 덮어씌우기)
	// whiten_strength가 1.0이면 완전한 하얀색이 됩니다.
	final_rgb = mix(final_rgb, vec3(1.0), whiten_strength);
	
	vec4 final_color = vec4(final_rgb, base_color.a);
	
	// E. 디졸브 처리
	float n_val = texture(noise_tex, n_uv).r;
	if (n_val < dissolve_amount) {
		final_color.a = 0.0;
	} else if (dissolve_amount > 0.0 && n_val < dissolve_amount + edge_thickness) {
		final_color.rgb = mix(final_color.rgb, edge_color.rgb * edge_intensity, edge_color.a);
	}
	
	COLOR = final_color;
}