shader_type canvas_item;

// 1.0이면 정방향, -1.0이면 좌우 반전
uniform float flip_scale = 1.0;

void fragment() {
	vec2 uv = UV;
	if (flip_scale < 0.0) {
		uv.x = 1.0 - uv.x;
	}
	COLOR = texture(TEXTURE, uv) * COLOR;
}