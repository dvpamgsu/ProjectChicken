shader_type canvas_item;

void fragment() {
	// 1. UV 좌표의 중심점(0.5, 0.5)으로부터의 거리 계산
	float dist = distance(UV, vec2(0.5));

	// 2. 거리가 0.5보다 크면(원 밖이면) 투명하게 처리
	// smoothstep을 사용하면 경계선이 부드러워집니다.
	float alpha = smoothstep(0.5, 0.49, dist);

	// 3. 원래 이미지 색상에 계산된 알파값을 곱함
	vec4 tex_color = texture(TEXTURE, UV);
	COLOR = vec4(tex_color.rgb, tex_color.a * alpha);
}