shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform vec2 center; // 이제 0.0 ~ 1.0 사이의 UV 좌표를 받습니다.
uniform float force;
uniform float size;
uniform float blast;

uniform vec2 direction;
uniform float aperture : hint_range(0.0, 3.141516, 0.001);

uniform float red_offset : hint_range(0.0, 2.0, 0.001);
uniform float green_offset : hint_range(0.0, 2.0, 0.001);
uniform float blue_offset : hint_range(0.0, 2.0, 0.001);

void fragment() {
	// SCREEN_UV는 이미 0~1 사이의 값입니다.
	float dist = distance(SCREEN_UV, center);
	vec2 norm = normalize(SCREEN_UV - center);

	// 방향 및 마스크 계산
	float angle = acos(dot(normalize(vec2(-direction.x, -direction.y)), -norm));
	float mask = cos((angle * 1.5707963268) / (aperture + 0.00001)) * step(angle, aperture) * force;

	// UV 기반이므로 blast와 size도 0.0 ~ 1.0 사이의 상대적 값을 가집니다.
	float blast_mask = smoothstep(blast - size/2.0, blast, dist);
	float total_size = blast + (size / 2.0);

	vec3 offsets = vec3(red_offset, green_offset, blue_offset);
	vec3 forces = offsets * mask * blast_mask;
	vec3 raw_eases = total_size * offsets;

	raw_eases = clamp(dist / max(raw_eases, vec3(0.0001)), vec3(0.0), vec3(1.0));
	vec3 easings = pow(raw_eases, forces);
	vec3 deforms = easings * dist;

	// SCREEN_UV에 왜곡(deforms)을 더해 바로 샘플링합니다.
	COLOR = vec4(
		texture(SCREEN_TEXTURE, center + (deforms.r * norm)).r,
		texture(SCREEN_TEXTURE, center + (deforms.g * norm)).g,
		texture(SCREEN_TEXTURE, center + (deforms.b * norm)).b,
		1.0
	);
}