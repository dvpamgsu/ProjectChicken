shader_type canvas_item;

// --- [유니폼 설정] ---
uniform float blur_radius : hint_range(0.0, 20.0) = 3.0;
uniform float alpha_persistence : hint_range(0.0, 1.0) = 0.5;

uniform float brightness : hint_range(0.0, 2.0) = 1.0;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;

// [새로운 추가] 위쪽 경계선을 얼마나 부드럽게 깎을지 (0.01 ~ 0.1 권장)
uniform float top_softness : hint_range(0.0, 0.2) = 0.05;

void fragment() {
	// 원본 데이터 저장
	vec4 origin_color = texture(TEXTURE, UV);
	vec4 col_accum = vec4(0.0);

	if (blur_radius <= 0.0) {
		col_accum = origin_color;
	} else {
		vec2 tex_size = TEXTURE_PIXEL_SIZE;
		float samples = 0.0;

		// 박스 블러 루프
		for (float x = -blur_radius; x <= blur_radius; x += 1.0) {
			for (float y = -blur_radius; y <= blur_radius; y += 1.0) {
				vec2 offset = vec2(x, y) * tex_size;

				// [Region & Repeat 대응 핵심]
				// UV가 범위를 넘어가도 fract를 통해 이미지 안으로 순환시킵니다.
				vec2 sample_uv = fract(UV + offset);

				col_accum += texture(TEXTURE, sample_uv);
				samples += 1.0;
			}
		}
		col_accum /= samples;
	}

	// --- [색상 조절 로직] ---
	vec3 rgb = col_accum.rgb * brightness;

	// 채도 조절 (Luminance 공식)
	float luminance = dot(rgb, vec3(0.299, 0.587, 0.114));
	rgb = mix(vec3(luminance), rgb, saturation);

	// --- [알파 및 위쪽 경계선 보정] ---
	float mixed_alpha = mix(col_accum.a, origin_color.a, alpha_persistence);

	// [핵심 수정 포인트] 위쪽 경계선만 날리는 마스크
	if (top_softness > 0.0) {
		// Region 반복 상태이더라도 각 개별 이미지의 '지역 UV'를 가져옵니다.
		vec2 local_uv = fract(UV);

		// smoothstep을 사용해 y좌표 0.0(맨 위)부터 top_softness까지 서서히 투명해지는 마스크를 만듭니다.
		float top_mask = smoothstep(0.0, top_softness, local_uv.y);

		// 최종 알파에 마스크를 곱해 위쪽 경계선을 날립니다.
		mixed_alpha *= top_mask;
	}

	COLOR = vec4(rgb, mixed_alpha);
}