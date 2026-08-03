shader_type canvas_item;

// --- إعدادات تأثير الانتقال ---
uniform float transition_size : hint_range(0.0, 1.0) = 1.0;

uniform vec2 player_screen_pos;
uniform float player_light_radius = 120.0;

uniform vec2 echo_positions[10];
uniform float echo_radii[10];
uniform float echo_opacities[10];
uniform int active_echoes_count = 0;

// إعدادات اللون والتوهج
uniform vec3 glow_color : source_color = vec3(0.0, 0.7, 1.0); // أزرق سماوي
uniform float echo_intensity : hint_range(0.1, 5.0) = 1.6;
uniform float ambient_darkness : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    float visibility = 0.0;
    
    // 1. ضوء اللاعب الدائم
    float player_dist = distance(FRAGCOORD.xy, player_screen_pos);
    if (player_dist <= player_light_radius) {
        visibility = (1.0 - (player_dist / player_light_radius)) * 0.7;
    }
    
    // 2. إضاءة الموجات تستجيب للحجم الحقيقي
    for (int i = 0; i < active_echoes_count; i++) {
        float echo_radius = echo_radii[i];
        float echo_opacity = echo_opacities[i];
        
        if (echo_radius > 0.0 && echo_opacity > 0.0) {
            float echo_dist = distance(FRAGCOORD.xy, echo_positions[i]);
            
            if (echo_dist <= echo_radius) {
                float rel_dist = echo_dist / echo_radius;
                
                // السر هنا: الإضاءة كاملة حتى 75% من القطر، والتنعيم يكون في آخر 25% عند الحافة
                float disk_vis = smoothstep(1.0, 0.6, rel_dist);
                
                disk_vis *= echo_opacity * echo_intensity;
                visibility = max(visibility, disk_vis);
            }
        }
    }
    
    visibility = clamp(visibility, 0.0, 1.0);
    
    // 3. تطبيق التوهج الأزرق الناعم
    vec3 base_black = vec3(0.0, 0.0, 0.0);
    vec3 glow_effect = glow_color * visibility * 0.4;
    
    // إخراج السواد مع التوهج والشفافية لإظهار البيئة
    COLOR = vec4(base_black + glow_effect, (1.0 - visibility) * ambient_darkness);
	
	// 4. تطبيق قناع الانتقال متمركزاً على موقع اللاعب
	float max_radius = 1500.0; // شعاع كافٍ لتغطية الشاشة بالكامل
	float current_trans_radius = max_radius * transition_size;
	float dist_from_player = distance(FRAGCOORD.xy, player_screen_pos);

	// إخفاء كل ما هو خارج نطاق دائرة الانتقال
	float transition_mask = smoothstep(current_trans_radius, current_trans_radius - 10.0, dist_from_player);
	visibility *= transition_mask;
}