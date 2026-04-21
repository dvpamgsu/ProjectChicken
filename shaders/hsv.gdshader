shader_type canvas_item;

// --- [유니폼 설정] ---
uniform float hue_shift : hint_range(-1.0, 1.0) = 0.0;     // 색상 회전
uniform float saturation_scale : hint_range(0.0, 2.0) = 1.0; // 채도 배율 (0: 흑백, 1: 원본)
uniform float value_scale : hint_range(0.0, 2.0) = 1.0;      // 명도 배율 (0: 검정, 1: 원본)

// RGB를 HSV로 변환하는 함수
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// HSV를 RGB로 변환하는 함수
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // 1. RGB -> HSV 변환
    vec3 hsv = rgb2hsv(tex_color.rgb);
    
    // 2. 값 조절
    // 색상(Hue)은 0~1 사이에서 순환하도록 처리
    hsv.x = fract(hsv.x + hue_shift); 
    // 채도와 명도는 배율로 조절하고 0~1 사이로 제한
    hsv.y = clamp(hsv.y * saturation_scale, 0.0, 1.0);
    hsv.z = clamp(hsv.z * value_scale, 0.0, 1.0);
    
    // 3. HSV -> RGB 복원
    vec3 final_rgb = hsv2rgb(hsv);
    
    COLOR = vec4(final_rgb, tex_color.a);
}