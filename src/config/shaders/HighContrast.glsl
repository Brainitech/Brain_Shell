#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const float CONTRAST = 1.35; // Adjust this higher or lower to taste

void main() {
    vec4 c = texture(tex, v_texcoord);
    // Simple math to push darks darker and lights lighter
    vec3 color = (c.rgb - vec3(0.5)) * CONTRAST + vec3(0.5);
    fragColor = vec4(clamp(color, 0.0, 1.0), c.a);
}
