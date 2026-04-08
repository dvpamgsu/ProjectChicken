shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform vec2 center;
uniform vec2 direction;
uniform float force : hint_range(0.0, 1.0) = 1.0;
uniform float blast : hint_range(0.0, 1.5) = 1.0;
uniform float fading_radius : hint_range(0.0, 1.5) = 0.0;

uniform float seed : hint_range(0.0, 100.0) = 1.0;
uniform int iterations = 4;
uniform float split_angle = 0.4; // 꺾이는 각도
uniform float crack_width = 0.003;
uniform vec4 crack_color : source_color = vec4(0.95, 0.95, 1.0, 1.0);

// --- 디버깅용 ---
uniform bool DEBUG_MODE = false;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453123);
}

float line_seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a, ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return smoothstep(crack_width, crack_width * 0.5, length(pa - ba * h));
}

void fragment() {
	// 1. 화면 비율 보정 (매우 중요)
	vec2 aspect = vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	vec2 uv = SCREEN_UV * aspect;
	vec2 adj_center = center * aspect;
	vec2 dir = normalize(direction * aspect);

	float crack_line = 0.0;

	// 2. 재귀적 뿌리 생성 로직
	for (int i = 0; i < 3; i++) {
		float i_f = float(i);
		vec2 curr_pos = adj_center;
		// 시작 각도에 약간의 랜덤 오프셋
		float curr_ang = atan(dir.y, dir.x) + (hash(vec2(i_f, seed)) - 0.5) * 0.5;

		for (int j = 0; j < iterations; j++) {
			float j_f = float(j);
			vec2 rnd_seed = vec2(i_f, j_f + seed);

			// 마디 길이와 꺾임 계산
			float seg_len = 0.15 + hash(rnd_seed) * 0.15;
			float ang_off = (hash(rnd_seed + 1.23) - 0.5) * split_angle;

			vec2 next_pos = curr_pos + vec2(cos(curr_ang), sin(curr_ang)) * seg_len;

			// 현재 픽셀이 이 직선 구간에 있는지 확인
			crack_line = max(crack_line, line_seg(uv, curr_pos, next_pos));

			// 다음 마디로 이동
			curr_pos = next_pos;
			curr_ang += ang_off;

			// 가지 갈라짐 (Branching)
			if (hash(rnd_seed + 4.56) > 0.6) {
				float fork_ang = curr_ang + (hash(rnd_seed + 7.89) - 0.5) * 1.2;
				vec2 fork_next = curr_pos + vec2(cos(fork_ang), sin(fork_ang)) * seg_len * 0.6;
				crack_line = max(crack_line, line_seg(uv, curr_pos, fork_next));
			}
		}
	}

	// 3. 애니메이션 마스크 (부드러운 소멸 버전)
	float d = distance(SCREEN_UV, center);

	// step 대신 smoothstep을 사용하여 안쪽 경계를 부드럽게 깎아냅니다.
	float outer_edge = step(d, blast);
	float inner_edge = smoothstep(fading_radius - 0.1, fading_radius, d);

	float mask = crack_line * outer_edge * inner_edge * force;

	// 4. 배경색 반전 로직
	vec4 tex = texture(SCREEN_TEXTURE, SCREEN_UV);

	// 색상 반전 처리 (1.0 - 원본색)
	vec3 inverted_col = 1.0 - tex.rgb;

	// 선택 사항: 반전된 색이 너무 강하다면, 특정 색상(crack_color)과 곱하거나 섞어서 톤을 조절할 수 있습니다.
	// 여기서는 순수 반전색을 mask만큼 적용합니다.
	vec3 final_col = mix(tex.rgb, inverted_col, mask);

	COLOR = vec4(final_col, 1.0);
}