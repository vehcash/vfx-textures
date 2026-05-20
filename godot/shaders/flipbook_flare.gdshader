shader_type spatial;
render_mode cull_disabled, blend_mix, depth_draw_opaque;

// Flipbook texture
uniform sampler2D flipbook_tex : source_color;

// Flipbook layout (configurable)
uniform int rows : hint_range(1, 32) = 4;
uniform int cols : hint_range(1, 32) = 4;

// Sprite rotation in 90° steps (0, 90, 180, 270)
uniform int rotation_steps : hint_range(0, 3) = 0;

// Albedo tint
uniform vec3 albedo_color : source_color = vec3(1.0);

// Emission
uniform vec3 emission_color : source_color = vec3(1.0);
uniform float emission_strength : hint_range(0.0, 10.0) = 0.0;

// Life ratio passed from vertex to fragment
varying float life_ratio_v;

void vertex() {
    // Recompute the same life ratio the particle shader uses
    float life_ratio = INSTANCE_CUSTOM.w;
    life_ratio_v = life_ratio;
}

void fragment() {
    int total_frames = rows * cols;

    float life_ratio = clamp(life_ratio_v, 0.0, 0.9999);

    int frame = int(floor(life_ratio * float(total_frames)));

    vec2 tile_size = vec2(1.0 / float(cols), 1.0 / float(rows));
    vec2 local_uv = UV;

    if (rotation_steps == 1) {
        local_uv = vec2(local_uv.y, 1.0 - local_uv.x);
    }
    else if (rotation_steps == 2) {
        local_uv = vec2(1.0 - local_uv.x, 1.0 - local_uv.y);
    }
    else if (rotation_steps == 3) {
        local_uv = vec2(1.0 - local_uv.y, local_uv.x);
    }

    vec2 tile_uv = local_uv * tile_size;

    int fx = frame % cols;
    int fy = frame / cols;
    vec2 offset = vec2(float(fx), float(fy)) * tile_size;

    vec2 uv = tile_uv + offset;

    float v = texture(flipbook_tex, uv).r;

    ALBEDO   = albedo_color * v;
    ALPHA    = v * COLOR.r;
    EMISSION = emission_color * emission_strength * v * COLOR.r;
}
