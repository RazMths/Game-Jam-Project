shader_type canvas_item;

// transition_size: 1.0 (رؤية كاملة بدون أي تعتيم) -> 0.0 (إغلاق وتعتيم أسود كامل)
uniform float transition_size : hint_range(0.0, 1.0) = 1.0;

// موقع اللاعب على الشاشة بالنطاق الموحد (من 0.0 إلى 1.0)
uniform vec2 player_screen_pos = vec2(0.5, 0.5);
uniform vec4 overlay_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    // 1. جلب الحجم الفعلي الكامل للشاشة بالبكسل
    vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
    
    // 2. تحويل جميع الإحداثيات من (0..1) إلى بكسلات حقيقية لمنع التشوه بملء الشاشة
    vec2 current_pixel = UV * screen_size;
    vec2 center_pixel = player_screen_pos * screen_size;
    
    // 3. حساب المسافة الحقيقية بالبكسل من المركز
    float dist = distance(current_pixel, center_pixel);
    
    // 4. حساب أطول قطر ممكن للوصول لزوايا الشاشة (الوتر المائل للشاشة)
    float max_possible_distance = length(screen_size);
    
    // 5. نصف القطر الحالي مأخوذ بنسبة المتر المسجل
    float current_radius = max_possible_distance * transition_size;
    
    // حافة ناعمة بحجم ثابت بالبكسل (مثلاً 40 بكسل)
    float smoothness = 40.0;
    float alpha = smoothstep(current_radius - smoothness, current_radius, dist);
    
    COLOR = vec4(overlay_color.rgb, alpha * overlay_color.a);
}