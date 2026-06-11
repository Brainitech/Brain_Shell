#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    
    // Classic sepia matrix
    float r = dot(pixColor.rgb, vec3(0.393, 0.769, 0.189));
    float g = dot(pixColor.rgb, vec3(0.349, 0.686, 0.168));
    float b = dot(pixColor.rgb, vec3(0.272, 0.534, 0.131));
    
    fragColor = vec4(r, g, b, pixColor.a);
}
