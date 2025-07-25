shader_type canvas_item;

uniform sampler2D mask_texture;
uniform bool white_reveals = true; // Black hides

void fragment() {
    vec4 mask_color = texture(mask_texture, UV);
    float mask_alpha;

    if (white_reveals) {
        mask_alpha = mask_color.r; // Use red channel as mask
    } else {
        mask_alpha = 1.0 - mask_color.r; // Use inverse of red channel
    }

    COLOR.rgb = COLOR.rgb; // Keep original color
    COLOR.a = mask_alpha; // Apply alpha from mask
}