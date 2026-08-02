shader_type canvas_item;

uniform vec2 mouse_position;           // موقع الفأرة بالبكسل
uniform float light_radius = 180.0;    // حجم ضوء الفأرة
uniform vec3 glow_color : source_color = vec3(0.0, 0.7, 1.0); // لون التوهج
uniform float ambient_darkness : hint_range(0.0, 1.0) = 0.92;

// مصفوفات لإضاءة الموجات عند الكبس والتمرير
uniform vec2 wave_positions[5];
uniform float wave_radii[5];
uniform float wave_opacities[5];
uniform int active_waves_count = 0;

void fragment() {
    float visibility = 0.0;

    // 1. حساب ضوء الفأرة المباشر (FRAGCOORD.xy تطابق get_global_mouse_position مباشرة)
    float mouse_dist = distance(FRAGCOORD.xy, mouse_position);
    if (mouse_dist <= light_radius) {
        visibility = smoothstep(light_radius, light_radius * 0.2, mouse_dist) * 0.85;
    }

    // 2. حساب إضاءة موجات الصدى (عند الكبس أو التمرير)
    for (int i = 0; i < active_waves_count; i++) {
        float r = wave_radii[i];
        float op = wave_opacities[i];
        if (r > 0.0 && op > 0.0) {
            float d = distance(FRAGCOORD.xy, wave_positions[i]);
            if (d <= r) {
                float rel_d = d / r;
                float disk_vis = smoothstep(1.0, 0.75, rel_d) * op * 1.4;
                visibility = max(visibility, disk_vis);
            }
        }
    }

    visibility = clamp(visibility, 0.0, 1.0);

    // 3. تأثير التوهج الأزرق
    vec3 glow = glow_color * visibility * 0.45;

    // إخراج السواد مع التوهج الشفاف
    COLOR = vec4(glow, (1.0 - visibility) * ambient_darkness);
}