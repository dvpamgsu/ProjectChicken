shader_type canvas_item;

uniform sampler2D noise_texture : repeat_enable, filter_linear;

uniform vec4 color_core : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 color_mid : source_color = vec4(1.0, 0.8, 0.2, 1.0);
uniform vec4 color_edge : source_color = vec4(0.8, 0.1, 0.0, 1.0);

uniform float speed : hint_range(0.1, 10.0) = 4.0;
uniform float noise_density : hint_range(0.1, 5.0) = 1.0;
uniform float beam_thickness : hint_range(0.01, 0.5) = 0.08;
uniform float exponential_power : hint_range(1.0, 15.0) = 7.0; // [요구사항 1] 왼쪽 가늘기

uniform float impact_spread : hint_range(1.0, 30.0) = 22.0; // [요구사항 2] 오른쪽 팽창 강도
uniform float impact_start : hint_range(0.1, 1.0) = 0.65;   // 팽창 시작 지점

// [추가 요청] 안쪽 레이어 두께 조절 (최외곽선 대비 비율)
uniform float mid_width_ratio : hint_range(0.0, 1.0) = 0.7;  // 중간색 폭
uniform float core_width_ratio : hint_range(0.0, 1.0) = 0.45; // 코어색 폭

uniform float cut_off_point : hint_range(0.8, 1.0) = 0.95;
uniform float bluntness : hint_range(0.1, 10.0) = 3.0;     // [요구사항 4] 뭉툭함 조절

void fragment() {
	vec2 uv = UV;
	float x_dist = uv.x;

	// 1. 노이즈 및 왼쪽 가늘기 (시작점 최소화)
	vec2 noise_uv = uv * noise_density;
	noise_uv.x -= TIME * speed;
	float noise_val = texture(noise_texture, noise_uv).r;

	// taper: 왼쪽은 0에 수렴, 오른쪽으로 갈수록 기하급수적으로 넓어지는 기본 실루엣
	float taper = pow(x_dist, exponential_power) * beam_thickness;

	// 2. 오른쪽 끝 급격한 팽창 및 일렁임
	float impact_zone = smoothstep(impact_start, 1.0, x_dist);
	float swell = impact_zone * impact_spread;
	// [요구사항 3] Wobble이 taper와 swell에 모두 영향을 받아 역동적으로 일렁임
	float wobble = (noise_val - 0.5) * (taper + swell * taper);

	// 3. [요구사항 4] 코사인 대신 원의 방정식 기반 완만한 수축 엔진 (Bullet-head)
	// sqrt(1.0 - pow(x, bluntness)) 형태의 원형 곡선을 사용하여 오른쪽 끝부분의 곡률을 제어합니다.
	// sqrt(1.0 - pow(shrink_factor, bluntness)) 식을 사용하여 코어와 중간층이 바늘처럼 뾰족하게 수축하며 사라지게 만듦
	// Bluntness 값을 2.0에서 더 높여보시면 오른쪽 끝단이 마치 망치로 친 것처럼 더 수직에 가깝게 뭉툭해지는 것을 확인하실 수 있습니다.
	float round_engine = sqrt(1.0 - pow(impact_zone, bluntness));

	// 코어와 중간색은 더 빨리 닫히게 설정하여 외곽선이 감싸는 입체감 유도
	float core_shrink = pow(round_engine, 3.0); // 가장 빨리 닫힘 (안쪽에서 끝남)
	float mid_shrink = pow(round_engine, 1.5);  // 중간 속도로 닫힘 (코어를 감쌈)
	float edge_shrink = round_engine;           // 가장 늦게까지 남음 (가장자리 형성)

	// 4. 최종 폭 합산
	float dist = abs(uv.y - 0.5);
	// (기본 + 팽창 + 흔들림)을 계산한 뒤 마지막에 원형 곡선으로 깎음
	float outer_border = (taper + swell * taper + wobble) * edge_shrink;

	// 안쪽 레이어 폭 (Wobble을 따르되, 끝부분에서 급격히 사라짐)
	// [추가 요청 사항] user uniform 변수 사용
	float mid_border = (taper + swell * taper + wobble) * mid_width_ratio * mid_shrink;
	float core_border = (taper + swell * taper + wobble) * core_width_ratio * core_shrink;

	// 5. 마스크 생성
	float x_mask = step(0.001, x_dist) * step(x_dist, cut_off_point);

	float beam_mask = smoothstep(outer_border, outer_border - 0.03, dist);
	float mid_mask = smoothstep(mid_border, mid_border - 0.05, dist);
	float core_mask = smoothstep(core_border, core_border - 0.08, dist);

	// 6. [핵심] 색상 합성 순서 (가장 안쪽부터 코어, 중간, 가장자리 순으로 쌓기)
	// 오른쪽 끝으로 갈수록 core_mask와 mid_mask가 0이 되어 color_edge만 남게 됩니다.
	vec3 final_rgb = color_edge.rgb;
	final_rgb = mix(final_rgb, color_mid.rgb, mid_mask);
	final_rgb = mix(final_rgb, color_core.rgb, core_mask);

	// 노이즈 질감
	final_rgb *= (0.6 + noise_val * 0.7);

	// 최종 알파 처리 (절단면을 뭉툭하게 유지)
	float presence = beam_mask;
	float final_alpha = step(0.01, presence) * x_mask;

	COLOR = vec4(final_rgb * 2.0, final_alpha);
}