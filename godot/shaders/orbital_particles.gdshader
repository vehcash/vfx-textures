shader_type particles;

// =============================================================
// PARAMETERS
// =============================================================
uniform float radius = 1.0;
uniform float particle_size = 1.0;
uniform float twist_amount = 0.0;

uniform float angle_offset = 0.0;
uniform float angle_offset_secondary = 0.0;

uniform float scale = 1.0;

uniform vec3 camera_pos;
uniform float perimeter_ratio = 0.0; // 0 = normal, 1 = rim-only

uniform sampler2D color_curve : source_color;

// =============================================================
// HASH
// =============================================================
float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

// =============================================================
// START: RANDOM DIRECTION ON SPHERE
// =============================================================
void start() {
    float seed = TIME * 123.456;

    float u = hash(float(INDEX) * 12.9898 + seed);
    float v = hash(float(INDEX) * 78.233  + seed);

    float theta = 2.0 * PI * u;
    float phi   = acos(2.0 * v - 1.0);

    vec3 dir = vec3(
        sin(phi) * cos(theta),
        sin(phi) * sin(theta),
        cos(phi)
    );

    CUSTOM = vec4(dir, 0.0); // xyz = direction, w = lifetime progress
}

// =============================================================
// PROCESS
// =============================================================
void process() {
    vec3 dir = normalize(CUSTOM.xyz);
    vec3 emitter_center = EMISSION_TRANSFORM[3].xyz;

    // =========================================================
    // CAMERA-BASED PERIMETER PROJECTION
    // =========================================================
    if (perimeter_ratio > 0.0) {
        // Direction from camera to emitter
        vec3 cam_dir = normalize(emitter_center - camera_pos);

        // Remove forward component → rim direction
        vec3 projected = dir - cam_dir * dot(dir, cam_dir);
        projected = normalize(projected);

        // Blend between original and rim-locked direction
        dir = normalize(mix(dir, projected, perimeter_ratio));
    }

    // =========================================================
    // FINAL POSITION
    // =========================================================
    vec3 pos = emitter_center + dir * radius;

    // =========================================================
    // ORIENTATION BASIS
    // =========================================================
    vec3 n = dir;
    vec3 up = abs(n.y) > 0.99 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);

    vec3 right = normalize(cross(up, n));
    vec3 new_up = cross(n, right);

    // ---------------------------------------------------------
    // TWIST
    // ---------------------------------------------------------
    float t = hash(float(INDEX) * 99.123) * twist_amount;
    float s = sin(t);
    float c = cos(t);

    vec3 right_rot = right * c + new_up * s;
    vec3 up_rot    = new_up * c - right * s;
    vec3 forward   = n;

    // ---------------------------------------------------------
    // PRIMARY ANGULAR OFFSET
    // ---------------------------------------------------------
    float ao = radians(angle_offset);
    float sa = sin(ao);
    float ca = cos(ao);

    vec3 right2 = right_rot * ca + up_rot * sa;
    vec3 up2    = up_rot * ca - right_rot * sa;

    right_rot = right2;
    up_rot    = up2;

    // ---------------------------------------------------------
    // SECONDARY ANGULAR OFFSET
    // ---------------------------------------------------------
    float ao2 = radians(angle_offset_secondary);
    float sb = sin(ao2);
    float cb = cos(ao2);

    vec3 right3 = right_rot * cb + forward * sb;
    vec3 forward2 = forward * cb - right_rot * sb;

    right_rot = right3;
    forward   = forward2;

    // ---------------------------------------------------------
    // SCALE
    // ---------------------------------------------------------
    float final_scale = scale * particle_size;
    right_rot *= final_scale;
    up_rot    *= final_scale;
    forward   *= final_scale;

    // =========================================================
    // WRITE TRANSFORM
    // =========================================================
    TRANSFORM[0] = vec4(right_rot, 0.0);
    TRANSFORM[1] = vec4(up_rot,    0.0);
    TRANSFORM[2] = vec4(forward,   0.0);
    TRANSFORM[3] = vec4(pos,       1.0);

    // =========================================================
    // LIFETIME + COLOR
    // =========================================================
    CUSTOM.w = clamp(CUSTOM.w + DELTA / LIFETIME, 0.0, 1.0);
    COLOR = texture(color_curve, vec2(CUSTOM.w, 0.5));
}
