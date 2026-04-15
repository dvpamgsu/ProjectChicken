shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float strength: hint_range(0.0, 0.1) = 0.05;
uniform vec2 center = vec2(0.5, 0.5);
uniform float max_radius = 1.5;

uniform float aberration: hint_range(0.0, 1.0) = 0.5;
uniform float width: hint_range(0.0, 0.1) = 0.04;
uniform float feather: hint_range(0.0, 1.0) = 0.1;

uniform float border_width : hint_range(0.0, 0.1) = 0.01;
uniform vec4 border_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform vec2 rect_size = vec2(1.0, 1.0);
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	// 1. 비율 보정 좌표계
	float node_aspect = rect_size.x / rect_size.y;
	vec2 uv_dist = UV;
	uv_dist.x *= node_aspect;
	vec2 corrected_center = center;
	corrected_center.x *= node_aspect;

	float dist = distance(uv_dist, corrected_center);

	// 2. 0.0~0.5와 0.5~1.0 구간 로직 분리
	bool is_restoring = progress > 0.5;

	// 각 구간 내에서 0.0 ~ 1.0으로 다시 매핑된 내부 progress
	float inner_p = is_restoring ? (progress - 0.5) * 2.0 : progress * 2.0;
	float radius = inner_p * max_radius;
	float activation = smoothstep(0.001, 0.01, inner_p);

	// 3. 왜곡 좌표 계산
	float distort_mask = (1.0 - smoothstep(radius - feather, radius, dist)) *
						 smoothstep(radius - width - feather, radius - width, dist) * activation;

	vec2 dir = normalize(uv_dist - corrected_center);
	dir.x /= node_aspect;
	vec2 offset = dir * strength * distort_mask;
	vec2 distorted_uv = SCREEN_UV - offset;
	vec2 abber_vec = offset * aberration;

	// 4. 색상 샘플링
	vec4 raw_col = texture(SCREEN_TEXTURE, distorted_uv); // 왜곡된 원색
	vec4 abber_col = vec4(
		texture(SCREEN_TEXTURE, distorted_uv + abber_vec).r,
		raw_col.g,
		texture(SCREEN_TEXTURE, distorted_uv - abber_vec).b,
		1.0
	);

	vec4 inv_col = vec4(1.0 - abber_col.rgb, 1.0); // 왜곡된 반전색
	vec4 bg_raw = texture(SCREEN_TEXTURE, SCREEN_UV); // 왜곡 없는 배경
	vec4 bg_inv = vec4(1.0 - bg_raw.rgb, 1.0); // 왜곡 없는 반전 배경

	// 5. 핵심: 구간별 색상 결정
	vec4 base_bg;   // 바탕이 되는 색
	vec4 wave_col;  // 퍼져나가는 원의 색

	if (!is_restoring) {
		// [1단계: 0.0~0.5] 원색 배경에서 반전 원이 커짐
		base_bg = bg_raw;
		wave_col = inv_col;
	} else {
		// [2단계: 0.5~1.0] 반전 배경에서 원색 원이 커짐
		base_bg = bg_inv;
		wave_col = abber_col;
	}

	// 6. 합성
	float wave_mask = (1.0 - smoothstep(radius, radius + feather, dist)) * activation;
	vec4 final_color = mix(base_bg, wave_col, wave_mask);

	// 7. 검은 테두리
	float border = (1.0 - smoothstep(radius + border_width, radius + border_width + 0.005, dist)) *
				   smoothstep(radius, radius + 0.005, dist) * activation;
	final_color = mix(final_color, border_color, border);

	COLOR = final_color;
}