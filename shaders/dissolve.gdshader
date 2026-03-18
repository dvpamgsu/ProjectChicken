shader_type canvas_item;

// source_color 대신 hint_default_white를 쓰면 텍스처가 없을 때 흰색(1.0)으로 처리되어 이미지가 보입니다.
uniform sampler2D dissolve_texture : hint_default_white;
uniform float dissolve_value : hint_range(0, 1);

void fragment() {
	vec4 main_texture = texture(TEXTURE, UV);
	vec4 noise_texture = texture(dissolve_texture, UV);
	
	// 로직 설명:
	// noise_texture.r이 dissolve_value보다 "크면" 1.0 (보임)
	// noise_texture.r이 dissolve_value보다 "작으면" 0.0 (투명)
	float alpha_mask = step(dissolve_value, noise_texture.r);
	
	main_texture.a *= alpha_mask;
	COLOR = main_texture;
}