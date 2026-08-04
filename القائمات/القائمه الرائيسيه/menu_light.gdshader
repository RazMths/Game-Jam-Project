shader_type canvas_item;

uniform vec2 mouse_position = vec2(0.5, 0.5); 
uniform float light_radius = 0.12;            
uniform float screen_aspect = 1.777;          

uniform vec3 glow_color : source_color = vec3(0.0, 0.7, 1.0);
uniform float ambient_darkness : hint_range(0.0, 1.0) = 0.92;

uniform vec2 wave_positions[10];
uniform float wave_radii[10];
uniform float wave_opacities[10];
uniform int active_waves_count = 0;

float get_aspect_distance(vec2 p1, vec2 p2, float aspect) {
    vec2 diff = p1 - p2;
    diff.x *= aspect;
    return length(diff);
}

void fragment() {
    float visibility = 0.0;

    // 1. ضوء الماوس المباشر
    float mouse_dist = get_aspect_distance(UV, mouse_position, screen_aspect);
    if (mouse_dist <= light_radius) {
        visibility = smoothstep(light_radius, light_radius * 0.2, mouse_dist) * 0.85;
    }

    // 2. إضاءة الموجات
    for (int i = 0; i < active_waves_count; i++) {
        float r = wave_radii[i];
        float op = wave_opacities[i];
        
        if (r > 0.0 && op > 0.0) {
            float d = get_aspect_distance(UV, wave_positions[i], screen_aspect);
            if (d <= r) {
                float rel_d = d / r;
                float disk_vis = smoothstep(1.0, 0.75, rel_d) * op * 1.4;
                visibility = max(visibility, disk_vis);
            }
        }
    }

    visibility = clamp(visibility, 0.0, 1.0);

    vec3 glow = glow_color * visibility * 0.45;
    COLOR = vec4(glow, (1.0 - visibility) * ambient_darkness);
}