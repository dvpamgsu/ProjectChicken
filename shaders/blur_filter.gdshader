shader_type canvas_item;

// 블러 강도를 조절하는 유니폼 (0.0 ~ 5.0 사이 추천)
uniform float blur_amount : hint_range(0.0, 5.0) = 2.0;
// 블러 처리된 화면을 다시 샘플링하기 위한 스크린 텍스처
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    // textureLod를 사용하여 SCREEN_TEXTURE의 낮은 밉맵 수준(LOD)을 참조합니다.
    // LOD 값이 높을수록 더 많이 뭉개집니다.
    vec4 blurred_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur_amount);
    
    // 최종 출력 색상 (블러된 배경 위에 살짝 어두운 필터를 씌울 수도 있습니다)
    COLOR = blurred_color;
}