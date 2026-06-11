#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    // Standard luminance weights
    float gray = dot(pixColor.rgb, vec3(0.2126, 0.7152, 0.0722));
    fragColor = vec4(vec3(gray), pixColor.a);
}
