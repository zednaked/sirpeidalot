shader_type canvas_item;

uniform vec2 mask_position = vec2(0.5, 0.5);
uniform vec2 mask_size     = vec2(0.2, 0.2);
uniform float darkness     = 0.7;
uniform float edge_softness = 0.05;

void fragment() {
    // Usa a UV normalizada da tela inteira
    vec2 uv = SCREEN_UV;  // SCREEN_UV varia de 0 a 1 na viewport inteira :contentReference[oaicite:1]{index=1}

    // Distância “quad” ao centro do buraco
    vec2 half = mask_size * 0.5;
    vec2 d = abs(uv - mask_position) - half;
    float dist = max(d.x, d.y);

    // Gradiente suave: dentro do buraco = 0, fora = 1
    float mask = smoothstep(0.0, edge_softness, dist);

    // Overlay escuro com alpha modulada
    COLOR = vec4(0.0, 0.0, 0.0, darkness * mask);
}
