shader_type canvas_item;

// --- 색상 설정 ---
uniform vec4 most_inner_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 inner_color : source_color = vec4(1.0, 1.0, 0.7, 1.0);
uniform vec4 mid_color : source_color = vec4(1.0, 0.5, 0.0, 1.0);
uniform vec4 outer_color : source_color = vec4(0.8, 0.1, 0.0, 1.0);

// --- 형태 및 애니메이션 설정 ---
uniform float core_radius : hint_range(0.0, 0.5) = 0.25;
uniform float fire_length : hint_range(0.0, 1.5) = 0.5;
uniform float fire_speed : hint_range(0.0, 20.0) = 4.0;
uniform float fire_detail : hint_range(1.0, 20.0) = 6.0;
uniform float fire_width : hint_range(0.1, 5.0) = 1.2; // 가로 폭 (클수록 날렵함)
uniform float opacity_boost : hint_range(1.0, 20.0) = 10.0;

// --- 노이즈 함수 ---
float rand(vec2 co) { return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453); }
float noise(vec2 uv) {
	vec2 i = floor(uv); vec2 f = fract(uv);
	float a = rand(i); float b = rand(i + vec2(1.0, 0.0));
	float c = rand(i + vec2(0.0, 1.0)); float d = rand(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
	vec2 uv_centered = UV - 0.5;
	float dist = length(uv_centered);

	// 1. [핵심 수정] 속도에 따른 세로 스트레칭 적용
	// fire_speed가 높아질수록 노이즈의 Y축 스케일을 줄여(나누기) 위로 길게 늘립니다.
	// 이렇게 해야 속도가 빨라져도 불꽃이 눕지 않고 수직으로 날렵하게 뽑힙니다.
	vec2 noise_uv = UV * fire_detail;
	noise_uv.x *= fire_width;
	noise_uv.y = (noise_uv.y / (1.0 + fire_speed * 0.2)) + (TIME * fire_speed);

	float n = noise(noise_uv);

	// 2. 하단부 밀착을 위한 마스크
	// 아래쪽으로 갈수록 노이즈 영향력을 줄여서 원형 테두리에 가깝게 만듭니다.
	float fire_intensity = smoothstep(0.85, 0.4, UV.y);
	float fire_mask = smoothstep(core_radius - 0.15, core_radius + 0.15, dist);

	// 3. 상단 테이퍼 (위로 갈수록 좁아짐)
	float taper = smoothstep(0.5, -0.2, uv_centered.y);

	// 4. 거리 왜곡 계산
	float distorted_dist = dist - (n * fire_length * fire_intensity * fire_mask * taper);

	// 5. 필터 및 색상 계산
	float fire_filter = smoothstep(core_radius + fire_length, core_radius, distorted_dist);
	float core_filter = smoothstep(core_radius + 0.01, core_radius - 0.01, dist);
	float most_inner_filter = smoothstep(core_radius * 0.4, 0.0, dist);

	vec4 final_color = mix(outer_color, mid_color, fire_filter);
	final_color = mix(final_color, inner_color, core_filter);
	final_color = mix(final_color, most_inner_color, most_inner_filter);

	// 6. 투명도 강화 및 하단 테두리 보정
	float fire_alpha = clamp(fire_filter * opacity_boost, 0.0, 1.0);

	// 원의 외곽선에 가까워지도록 하단 알파를 강하게 유지
	float circle_alpha = smoothstep(core_radius + 0.02, core_radius, dist);

	// 하단으로 갈수록 불꽃의 일렁임보다 원형의 외곽선을 우선시함
	float vertical_mix = smoothstep(0.5, 0.8, UV.y);
	float final_alpha = mix(fire_alpha, circle_alpha, vertical_mix);

	// 코어 본체는 절대 불투명
	final_alpha = max(final_alpha, core_filter);

	// 경계면 잘림 방지
	final_alpha *= smoothstep(0.5, 0.48, dist);

	COLOR = vec4(final_color.rgb, final_alpha);
}