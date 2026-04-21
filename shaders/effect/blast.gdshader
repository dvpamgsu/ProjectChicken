shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform vec2 center; // 0.0 ~ 1.0 사이의 UV 좌표
uniform float force;
uniform float size;
uniform float blast;

uniform float red_offset : hint_range(0.0, 2.0, 0.001);
uniform float green_offset : hint_range(0.0, 2.0, 0.001);
uniform float blue_offset : hint_range(0.0, 2.0, 0.001);

void fragment() {
	vec2 diff = SCREEN_UV - center;
	float dist = length(diff);

	if (dist < 0.0001) {
		// 중심점은 왜곡 없이 출력
		COLOR = texture(SCREEN_TEXTURE, SCREEN_UV);
	} else {
		vec2 norm = diff / dist;

		// [수정] aperture와 direction 관련 로직 제거
		// 항상 360도 전체에 적용되므로 mask는 단순히 force 값이 됩니다.
		float mask = force;

		float blast_mask = smoothstep(blast - size/2.0, blast, dist);
		float total_size = blast + (size / 2.0);

		vec3 offsets = vec3(red_offset, green_offset, blue_offset);
		vec3 forces = offsets * mask * blast_mask;
		vec3 raw_eases = total_size * offsets;

		// 나눗셈 안전장치
		raw_eases = clamp(dist / max(raw_eases, vec3(0.0001)), vec3(0.0), vec3(1.0));
		vec3 easings = pow(raw_eases, forces);
		vec3 deforms = easings * dist;

		// 최종 색상 샘플링 (모든 방향으로 균일하게 왜곡)
		COLOR = vec4(
			texture(SCREEN_TEXTURE, center + (deforms.r * norm)).r,
			texture(SCREEN_TEXTURE, center + (deforms.g * norm)).g,
			texture(SCREEN_TEXTURE, center + (deforms.b * norm)).b,
			1.0
		);
	}
}