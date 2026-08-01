shader_type canvas_item;

uniform vec2 player_screen_pos; // موقع اللاعب بالبكسل على الشاشة
uniform float inner_radius = 120.0; 
uniform float outer_radius = 450.0; 
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.85;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    // حساب المسافة بالبكسل مباشرة
    float dist = distance(FRAGCOORD.xy, vec2(player_screen_pos.x, player_screen_pos.y));
    
    float vignette = smoothstep(inner_radius, outer_radius, dist);
    
    COLOR = vec4(vignette_color.rgb, vignette * vignette_opacity);
}