shader_type canvas_item;

// --- [1. 기본 효과 유니폼] ---
uniform sampler2D noise_tex : repeat_enable, hint_default_black;
uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 edge_color : source_color = vec4(1.0, 0.5, 0.1, 1.0);
uniform float edge_thickness : hint_range(0.0, 0.2) = 0.05;
uniform float edge_intensity : hint_range(1.0, 10.0) = 3.0;
uniform float noise_scale : hint_range(0.01, 2.0) = 0.5; 

uniform float whiten_strength : hint_range(0.0, 1.0) = 0.0;
// [추가] 히트 효과 (빨간색)
uniform float hit_strength : hint_range(0.0, 1.0) = 0.0;
uniform float shadow_intensity : hint_range(0.0, 1.0) = 0.2;

// --- [2. 데이터 유니폼] ---
uniform vec2 sprite_size;      // 애니메이션 프레임의 실제 픽셀 크기
uniform int light_count = 0;
uniform vec2 light_offsets[8]; // 중심점 기준 광원 상대 좌표 (Pixels)
uniform vec4 light_colors[8];
uniform float light_intensities[8];

// --- [3. 림라이트 설정] ---
uniform float rim_thickness_base : hint_range(0.0, 10.0) = 2.0;
uniform float rim_expand_width : hint_range(0.0, 20.0) = 5.0;
uniform float rim_softness : hint_range(0.0, 1.0) = 0.5;
uniform float bloom_intensity : hint_range(0.0, 10.0) = 2.0;

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);
	
	// --- [A. 디졸브 로직] ---
	if (dissolve_amount > 0.0) {
		vec2 fixed_uv = (UV * sprite_size) * noise_scale * 0.01;
		float n_val = texture(noise_tex, fixed_uv).r;
		if (n_val < dissolve_amount) {
			discard;
		} else if (n_val < dissolve_amount + edge_thickness) {
			base_color.rgb = mix(base_color.rgb, edge_color.rgb * edge_intensity, edge_color.a);
		}
	}

	vec3 final_rgb = base_color.rgb * (1.0 - shadow_intensity);
	vec3 rim_accum = vec3(0.0);

	// --- [B. 픽셀별 다중 샘플링 림라이트] ---
	if (base_color.a > 0.0001) {
		vec2 pixel_pos_from_center = (UV - vec2(0.5)) * sprite_size;

		for (int i = 0; i < 8; i++) {
			if (i >= light_count) break;

			vec2 pixel_to_light = light_offsets[i] - pixel_pos_from_center;
			float dist_to_light = length(pixel_to_light);
			vec2 dir = normalize(pixel_to_light);

			float max_thickness = rim_thickness_base + (dist_to_light * 0.02);
			max_thickness = min(max_thickness, rim_thickness_base + rim_expand_width);

			float rim_soft_accum = 0.0;
			const int SAMPLES = 4; 
			
			for (int j = 1; j <= SAMPLES; j++) {
				float current_step = float(j) / float(SAMPLES);
				float check_dist = current_step * max_thickness;
				
				vec2 sample_pos = UV + (dir * TEXTURE_PIXEL_SIZE * check_dist);
				float alpha_sample = texture(TEXTURE, sample_pos).a;
				
				float mask_val = clamp(base_color.a - alpha_sample, 0.0, 1.0);
				rim_soft_accum += mask_val * (1.1 - current_step);
			}
			
			float rim_mask = (rim_soft_accum / float(SAMPLES));
			rim_mask = smoothstep(0.0, rim_softness, rim_mask);

			float attenuation = light_intensities[i] / max(dist_to_light * 0.005, 1.0);
			rim_accum += light_colors[i].rgb * attenuation * rim_mask;
		}
	}

	// --- [C. 최종 합성 및 색상 효과] ---
	final_rgb += rim_accum * bloom_intensity;
	
	// 1. 히트 효과 (빨간색으로 변함)
	// 빨간색의 정도를 조절할 수 있습니다. 여기서는 (1, 0, 0) 완전한 빨강을 썼습니다.
	vec3 hit_color = vec3(1.0, 0.0, 0.0);
	final_rgb = mix(final_rgb, hit_color, hit_strength);
	
	// 2. 화이트 피격 효과 (히트 효과보다 나중에 적용되어 최종적으로 흰색이 됨)
	final_rgb = mix(final_rgb, vec3(1.0), whiten_strength);
	
	COLOR = vec4(final_rgb, base_color.a);
}