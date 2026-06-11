#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

#define STRENGTH 0.003 // How far the red and blue channels split

void main() {
    vec2 offset = vec2(STRENGTH, 0.0);
    
    // Shift red right, keep green center, shift blue left
    float r = texture(tex, v_texcoord + offset).r;
    float g = texture(tex, v_texcoord).g;
    float b = texture(tex, v_texcoord - offset).b;
    
    fragColor = vec4(r, g, b, 1.0);
}
