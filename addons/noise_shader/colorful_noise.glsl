#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D screen_image;

// Details parameters to be sent to the shader
layout(push_constant, std430) uniform Params {
    vec2 raster_size;
    int value_steps;
    float value_speed;
    int hue_steps;
    float hue_speed;
    float hue_offset;
} params;

// The noise data the shader reads from
layout(set = 1, binding = 1, std430) restrict buffer FloatBufferIn {
    vec2 data[];
}
buffer_in;

// The noise data that the shader writes to
layout(set = 1, binding = 2, std430) restrict buffer FloatBufferOut {
    vec2 data[];
}
buffer_out;

// Returns the index of the buffer according to the uv coordinate
int get_buffer_index(in ivec2 uv, in ivec2 size) {
    return uv.y * size.x + uv.x;
}

// Update the buffer value according to the screen color and speed
void update_value(inout float value, in float brightness, in float speed) {
    value = value + clamp(brightness, 0.0, 1.0) * speed;
    value -= floor(value);
}

// Returns a brightness value according to the buffer value and number of steps
float get_brightness_from_value(in float value) {
    float brightness = floor(value * 2.0 * float(params.value_steps - 1));
    brightness = float(params.value_steps - 1) - abs(brightness - float(params.value_steps - 1));
    return brightness / float(params.value_steps - 1);
}

vec3 hsl_to_rgb(in float hue, in float saturation, in float lightness) {
    vec3 rgb = clamp(abs(mod(hue * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);

    return lightness + saturation * (rgb - 0.5) * (1.0 - abs(2.0 * lightness - 1.0));
}

vec3 hsv_to_rgb(vec3 hsv) {
    vec4 k = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(hsv.xxx + k.xyz) * 6.0 - k.www);
    return hsv.z * mix(k.xxx, clamp(p - k.xxx, 0.0, 1.0), hsv.y);
}

void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    ivec2 size = ivec2(params.raster_size);

    if (uv.x >= size.x || uv.y >= size.y) {
        return;
    }

    int index = get_buffer_index(uv, size);
    float value = buffer_in.data[index].x;
    float hue = buffer_in.data[index].y;
    vec4 screen_color = imageLoad(screen_image, uv);

    update_value(value, screen_color.r, params.value_speed);
    update_value(hue, screen_color.g, params.hue_speed);
    buffer_out.data[index].x = value;
    buffer_out.data[index].y = hue;

    hue = floor(hue * float(params.hue_steps)) / float(params.hue_steps);
    hue = fract(hue + params.hue_offset);
    value = pow(get_brightness_from_value(value), 3.0);
    screen_color.rgb = hsv_to_rgb(vec3(hue, 1.0, value));
    imageStore(screen_image, uv, screen_color);
}
