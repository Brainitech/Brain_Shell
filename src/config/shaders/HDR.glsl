#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 color = texture(tex, v_texcoord);

    // Milder contrast curve
    vec3 sCurve = color.rgb * color.rgb * (3.0 - 2.0 * color.rgb);
    color.rgb = mix(color.rgb, sCurve, 0.4); 

    // Gentle 10% saturation boost
    float luma = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    color.rgb = mix(vec3(luma), color.rgb, 1.10); 

    fragColor = vec4(clamp(color.rgb, 0.0, 1.0), color.a);
}
