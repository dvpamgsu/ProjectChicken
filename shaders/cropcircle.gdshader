shader_type canvas_item;

// Godot 4 전용 힌트 방식
uniform float border_width : hint_range(0.0, 0.1) = 0.1;
uniform vec4 border_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	// UV 중심점
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(UV, center);
	
	// 테두리와 내부 원 계산 (smoothstep으로 부드럽게)
	float radius = 0.5 - border_width;
	float inside_circle = smoothstep(radius, radius - 0.01, dist);
	float outside_circle = smoothstep(0.5, 0.49, dist);
	
	// 텍스처 색상 가져오기 (COLOR에는 Tint/Alpha 정보가 담겨 있음)
	vec4 tex_color = texture(TEXTURE, UV) * COLOR;
	
	// 테두리 영역 계산
	float border_mask = outside_circle - inside_circle;
	
	// 최종 색상 조합
	vec4 final_color = mix(vec4(0.0), border_color, border_mask); // 테두리 먼저 배치
	final_color = mix(final_color, tex_color, inside_circle);    // 그 위에 텍스처 배치
	
	// 전체 알파값 적용
	final_color.a *= outside_circle;
	
	COLOR = final_color;
}