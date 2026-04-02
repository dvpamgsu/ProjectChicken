shader_type canvas_item;

// --- [1. Dissolve 파라미터] ---
uniform sampler2D noise_tex : repeat_enable;
uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 edge_color : source_color = vec4(1.0, 0.5, 0.1, 1.0);
uniform float edge_thickness : hint_range(0.0, 0.2) = 0.05;
uniform float edge_intensity : hint_range(1.0, 10.0) = 3.0;
uniform float noise_scale : hint_range(0.1, 10.0) = 1.0;

// --- [2. Rim Light & Shadow 파라미터] ---
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float rim_thickness : hint_range(0.0, 20.0) = 5.0;
uniform vec2 light_direction = vec2(-1.0, -1.0);
uniform float rim_intensity : hint_range(0.0, 10.0) = 2.0;
uniform float rim_softness : hint_range(0.0, 1.0) = 0.5;
uniform float shadow_intensity : hint_range(0.0, 1.0) = 0.3;

// --- [3. 피격 이펙트(Hit Flash) 파라미터] - 추가됨 ---
uniform vec4 hit_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // 피격 색상 (기본 빨강)
uniform float hit_strength : hint_range(0.0, 1.0) = 0.0; // 0이면 원본, 1이면 완전 피격 색상

void fragment() {
	// --- A. UV 종횡비 보정 ---
	vec2 aspect_ratio = vec2(1.0 / TEXTURE_PIXEL_SIZE.x, 1.0 / TEXTURE_PIXEL_SIZE.y);
	float max_side = max(aspect_ratio.x, aspect_ratio.y);
	vec2 noise_uv = UV * (aspect_ratio / max_side) * noise_scale;

	// --- B. 원본 색상 및 부드러운 림 라이트 계산 ---
	vec4 base_color = texture(TEXTURE, UV);
	
	float rim_alpha = 0.0;
	vec2 move_dir = normalize(light_direction) * TEXTURE_PIXEL_SIZE;
	for (float i = 1.0; i <= 4.0; i++) {
		float step_dist = i * rim_thickness * 0.25;
		rim_alpha += texture(TEXTURE, UV - move_dir * step_dist).a;
	}
	rim_alpha /= 4.0;
	
	float is_rim = clamp(base_color.a - rim_alpha, 0.0, 1.0);
	is_rim = smoothstep(0.0, rim_softness + 0.1, is_rim);
	
	// --- C. 색상 합성 (그림자 + 림 라이트) ---
	vec3 shadow_applied_rgb = base_color.rgb * (1.0 - shadow_intensity);
	vec3 final_rgb = mix(shadow_applied_rgb, rim_color.rgb * rim_intensity, is_rim);
	
	// --- D. 피격 이펙트(Hit Flash) 적용 - 추가됨 ---
	// 기존의 모든 색상 계산이 끝난 후, 최종 RGB에 hit_color를 hit_strength 비율만큼 섞습니다.
	// 림 라이트나 그림자 위에 빨간색 톤이 덮어씌워지는 방식입니다.
	final_rgb = mix(final_rgb, hit_color.rgb, hit_strength * hit_color.a);
	
	vec4 final_color = vec4(final_rgb, base_color.a);
	
	// --- E. 노이즈 디졸브 및 에지 처리 ---
	float noise_val = texture(noise_tex, noise_uv).r;
	
	if (noise_val < dissolve_amount) {
		final_color.a = 0.0;
	} 
	else if (dissolve_amount > 0.0 && noise_val < dissolve_amount + edge_thickness) {
		// 디졸브 에지 컬러에도 피격 색상을 살짝 반영할지 선택할 수 있지만, 
		// 보통 타들어가는 불꽃색은 유지하는 것이 비주얼상 더 좋습니다.
		final_color.rgb = mix(final_color.rgb, edge_color.rgb * edge_intensity, edge_color.a);
	}
	
	COLOR = final_color;
}