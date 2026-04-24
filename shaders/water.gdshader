shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D noise_tex : repeat_enable, filter_linear_mipmap;

uniform vec4 water_color : source_color = vec4(0.1, 0.4, 0.6, 1.0);
uniform float reflection_strength : hint_range(0.0, 1.0) = 0.5;
uniform float water_line_y : hint_range(0.0, 1.0) = 0.5;
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.02;
uniform float wave_speed = 0.05;
uniform float reflection_v_compression : hint_range(0.1, 2.0) = 0.7;

// --- 윤슬(Sparkle) 강화 설정 ---
uniform vec4 sparkle_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float sparkle_intensity : hint_range(0.0, 10.0) = 3.0; // 반짝임 강도
uniform float sparkle_size : hint_range(0.0, 1.0) = 0.05;      // 작을수록 더 날카로운 파편이 됨
uniform float sparkle_stretch : hint_range(1.0, 50.0) = 15.0;  // 가로로 찢어지는 정도

void fragment() {
    // 1. 왜곡 및 반사 (기본 로직)
    vec2 noise_uv = vec2(SCREEN_UV.x, SCREEN_UV.y + TIME * wave_speed);
    float noise_val = texture(noise_tex, noise_uv).r;
    float distortion = (noise_val - 0.5) * distortion_strength;

    float dist_y = SCREEN_UV.y - water_line_y;
    vec2 reflect_uv = vec2(SCREEN_UV.x + distortion, water_line_y - dist_y * reflection_v_compression);
    reflect_uv = clamp(reflect_uv, vec2(0.0), vec2(1.0));
    vec4 reflection_col = texture(SCREEN_TEXTURE, reflect_uv);

    // 2. [핵심] 불규칙한 가로 파편 반짝임 로직
    // 서로 다른 속도로 움직이는 두 개의 UV를 만듭니다.
    vec2 sp_uv1 = SCREEN_UV * vec2(1.0 / sparkle_stretch, 1.0);
    sp_uv1 += vec2(TIME * wave_speed, TIME * wave_speed * 0.5);
    
    vec2 sp_uv2 = SCREEN_UV * vec2(1.2 / sparkle_stretch, 0.8);
    sp_uv2 -= vec2(TIME * wave_speed * 0.7, TIME * wave_speed * 1.2);

    // 두 노이즈를 섞어서 패턴의 반복을 제거합니다.
    float n1 = texture(noise_tex, sp_uv1).r;
    float n2 = texture(noise_tex, sp_uv2).r;
    float combined_noise = n1 * n2; // 두 노이즈가 겹치는 '정점'만 남음

    // pow 함수를 매우 높게 써서 빛을 아주 작은 파편으로 쪼갭니다.
    // sparkle_size가 작을수록 빛이 더 미세하고 불규칙하게 흩어집니다.
    float sparkle = pow(combined_noise, 1.0 / sparkle_size);
    
    // 수평선 근처에서만 강하게 발생하고 아래로 갈수록 자연스럽게 소멸
    sparkle *= step(water_line_y + 0.005, SCREEN_UV.y);
    sparkle *= (1.0 - smoothstep(0.0, 0.4, dist_y));

    // 3. 최종 색상 혼합
    vec3 base_rgb = mix(water_color.rgb, reflection_col.rgb, reflection_strength);
    vec3 final_sparkle = sparkle_color.rgb * sparkle * sparkle_intensity;
    
    COLOR = vec4(base_rgb + final_sparkle, 1.0);
}