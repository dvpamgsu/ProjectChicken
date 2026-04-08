shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform vec2 direction = vec2(1.0, 0.0);
uniform float amplitude = 0.0;
uniform float wave_phase = -0.2;
// 두께를 이전보다 늘려(0.15 -> 0.25) 더 묵직한 느낌을 줍니다.
uniform float wave_width = 0.25;

void fragment() {
	vec2 n_dir = normalize(direction);
	
	// 화면 중심 기준 거리 계산
	float dist = dot(UV - vec2(0.5), n_dir);
	
	// 화면 대각선 범위를 고려한 스캔 영역
	float range = abs(n_dir.x) * 0.5 + abs(n_dir.y) * 0.5;
	
	// 파동의 중심 위치 (phase에 따라 이동)
	float current_pos = mix(-range - wave_width, range + wave_width, wave_phase);
	
	// 직선 마스크 (두께가 늘어나 더 확실하게 보입니다)
	float mask = smoothstep(current_pos - wave_width, current_pos, dist) * smoothstep(current_pos + wave_width, current_pos, dist);
	
	// 색수차 강도 적용
	float shift = amplitude * mask;
	
	vec2 uv_r = SCREEN_UV - n_dir * shift;
	vec2 uv_g = SCREEN_UV;
	vec2 uv_b = SCREEN_UV + n_dir * shift;
	
	vec3 col;
	col.r = texture(SCREEN_TEXTURE, uv_r).r;
	col.g = texture(SCREEN_TEXTURE, uv_g).g;
	col.b = texture(SCREEN_TEXTURE, uv_b).b;
	
	COLOR = vec4(col, texture(SCREEN_TEXTURE, uv_g).a);
}