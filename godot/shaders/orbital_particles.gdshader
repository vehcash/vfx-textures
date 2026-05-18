shader_type particles;

uniform float radius = 1.0;
uniform float spark_size = 1.0;
uniform float twist_amount = 0.0;

// Angular offsets (in degrees)
uniform float angle_offset = 0.0;
uniform float angle_offset_secondary = 0.0;

// Random scale range
uniform float scale_min = 0.5;
uniform float scale_max = 1.5;

// Curve for color/alpha over lifetime
uniform sampler2D color_curve : source_color;

// Hash
float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

void start() {
    float seed = TIME * 123.456;

    float u = hash(float(INDEX) * 12.9898 + seed);
    float v = hash(float(INDEX) * 78.233  + seed);

    float theta = 2.0 * PI * u;
    float phi = acos(2.0 * v - 1.0);

    vec3 dir = vec3(
        sin(phi) * cos(theta),
        sin(phi) * sin(theta),
        cos(phi)
    );

    float rnd = hash(float(INDEX) * 345.678 + seed);
    float scale = mix(scale_min, scale_max, rnd);

    CUSTOM = vec4(dir, scale);
}

void process() {
    vec3 dir = normalize(CUSTOM.xyz);
    float scale = CUSTOM.w;

    vec3 emitter_center = EMISSION_TRANSFORM[3].xyz;
    vec3 pos = emitter_center + dir * radius;

    vec3 n = dir;
    vec3 up = vec3(0.0, 1.0, 0.0);

    if (abs(dot(n, up)) > 0.99) {
        up = vec3(1.0, 0.0, 0.0);
    }

    vec3 right = normalize(cross(up, n));
    vec3 new_up = cross(n, right);

    // Random twist
    float t = hash(float(INDEX) * 99.123) * twist_amount;
    float s = sin(t);
    float c = cos(t);

    vec3 right_rot = right * c + new_up * s;
    vec3 up_rot    = new_up * c - right * s;
    vec3 forward   = n;

    // -------------------------------
    // 🔥 1) Apply primary angular offset
    // -------------------------------
    float ao = radians(angle_offset);
    float sa = sin(ao);
    float ca = cos(ao);

    vec3 right2 = right_rot * ca + up_rot * sa;
    vec3 up2    = up_rot * ca - right_rot * sa;

    right_rot = right2;
    up_rot    = up2;

    // -------------------------------
    // 🔥 2) Optional secondary offset
    // -------------------------------
    float ao2 = radians(angle_offset_secondary);
    float sb = sin(ao2);
    float cb = cos(ao2);

    vec3 right3 = right_rot * cb + forward * sb;
    vec3 forward2 = forward * cb - right_rot * sb;

    right_rot = right3;
    forward   = forward2;

    // Apply scale
    right_rot *= scale * spark_size;
    up_rot    *= scale * spark_size;
    forward   *= scale * spark_size;

    TRANSFORM[0] = vec4(right_rot, 0.0);
    TRANSFORM[1] = vec4(up_rot,    0.0);
    TRANSFORM[2] = vec4(forward,   0.0);
    TRANSFORM[3] = vec4(pos, 1.0);

    float life_ratio = fract(TIME / LIFETIME + float(INDEX) * 0.123);
    COLOR = texture(color_curve, vec2(life_ratio, 0.5));
}
