shader_type spatial;

render_mode blend_mix, cull_back, depth_draw_opaque;

uniform sampler2D tex_front;
uniform sampler2D tex_left;
uniform sampler2D tex_right;

uniform float angle_sharpness = 4.0;
uniform float angle_ratio = 1.0;

// 0 = vertical stripes + left/right angle
// 1 = horizontal stripes + up/down angle
uniform int orientation_mode = 0;

uniform float stripe_frequency = 200.0;
uniform float stripe_strength = 0.25;

void fragment() {
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vec3 view_dir_world = normalize(CAMERA_POSITION_WORLD - world_pos);
    vec3 view_dir_local = (inverse(MODEL_MATRIX) * vec4(view_dir_world, 0.0)).xyz;

    float axis_a;
    float axis_b;

    // --- NEW: choose angle axes based on orientation ---
    if (orientation_mode == 0) {
        // Vertical stripes → angle based on left/right
        axis_a = view_dir_local.x;
        axis_b = view_dir_local.z;
    } else {
        // Horizontal stripes → angle based on up/down
        axis_a = view_dir_local.y;
        axis_b = view_dir_local.z;
    }

    float angle = atan(axis_a, axis_b);
    angle *= angle_ratio;
    angle = clamp(angle, -PI, PI);

    float w_front = pow(clamp(1.0 - abs(angle) / 1.0, 0.0, 1.0), angle_sharpness);
    float w_left  = pow(clamp((angle + 1.0) / 2.0, 0.0, 1.0), angle_sharpness);
    float w_right = pow(clamp((1.0 - angle) / 2.0, 0.0, 1.0), angle_sharpness);

    float sum = w_front + w_left + w_right + 0.0001;
    w_front /= sum;
    w_left  /= sum;
    w_right /= sum;

    vec4 col_front = texture(tex_front, UV);
    vec4 col_left  = texture(tex_left,  UV);
    vec4 col_right = texture(tex_right, UV);

    vec4 base = col_front * w_front + col_left * w_left + col_right * w_right;

    // --- NEW: stripe direction toggle ---
    float stripe_coord = (orientation_mode == 0) ? UV.x : UV.y;

    float stripe = sin(stripe_coord * stripe_frequency * 6.28318);
    stripe = (stripe * 0.5 + 0.5) * stripe_strength;

    base.rgb *= 1.0 - stripe;

    ALBEDO = base.rgb;
    ALPHA = base.a;
}
