shader_type canvas_item;

void fragment() {
	// 1. 원형 마스크 계산 로직
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(UV, center);

	// 2. 텍스처 색상 가져오기
	vec4 tex_color = texture(TEXTURE, UV);

	if (dist > 0.5) {
		// 원 밖은 투명
		COLOR = vec4(0.0);
	} else {
		// 3. (핵심) 텍스처 색상에 Tint(Modulate) 값을 곱해줍니다.
		// COLOR 변수에 COLOR를 곱하면 인스펙터의 Tint/Alpha가 적용됩니다.
		COLOR = tex_color * COLOR;
	}
}