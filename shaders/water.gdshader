shader_type canvas_item;

// 1. 전체 화면 텍스처
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform vec4 water_color : source_color = vec4(0.1, 0.4, 0.6, 1.0);
uniform float reflection_strength : hint_range(0.0, 1.0) = 0.5;
uniform float water_line_y : hint_range(0.0, 1.0) = 0.5;

uniform sampler2D noise_tex : repeat_enable;
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.02;
uniform float wave_speed = 0.05;

void fragment() {
    // 물결 왜곡 로직
    vec2 uv_offset = texture(noise_tex, vec2(SCREEN_UV.x, SCREEN_UV.y + TIME * wave_speed)).rg;
    float distortion = (uv_offset.x - 0.5) * distortion_strength;

    // 수평선 기준 반사 좌표 계산
    float distance_from_surface = SCREEN_UV.y - water_line_y;
    vec2 reflect_uv = vec2(SCREEN_UV.x + distortion, water_line_y - distance_from_surface);
	reflect_uv = clamp(reflect_uv, vec2(0.0), vec2(1.0));
    // [핵심] 소스 선택 로직
    vec4 reflection_col;

    // 전체 화면 사용 (SCREEN_TEXTURE)
    reflection_col = texture(SCREEN_TEXTURE, reflect_uv);
	

    // 최종 색상 혼합 (불투명 버전)
    vec3 final_rgb = mix(water_color.rgb, reflection_col.rgb, reflection_strength);
    COLOR = vec4(final_rgb, 1.0);
}