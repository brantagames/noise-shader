#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D screen_image;

// Details parameters to be sent to the shader
layout(push_constant, std430) uniform Params {
    vec2 raster_size;
    ivec2 direction;
    int speed_steps;
    int frame;
    float brightness_exponent;
} params;

// The noise data the shader reads from
layout(set = 1, binding = 1, std430) restrict buffer FloatBufferIn {
    float data[];
}
buffer_in;

// The noise data that the shader writes to
layout(set = 1, binding = 2, std430) restrict buffer FloatBufferOut {
    float data[];
}
buffer_out;

// Random values that the shader can pull from
layout(set = 1, binding = 3, std430) restrict buffer FloatRandomIn {
    float data[];
}
random_in;

// Returns the index of the buffer according to the uv coordinate
int get_buffer_index(in ivec2 uv, in ivec2 size) {
    return uv.y * size.x + uv.x;
}

// Wraps a screen coordinate so that it is always within the viewable area
ivec2 wrap(in ivec2 value, in ivec2 size) {
    return ivec2(mod(mod(value, size) + size, size));
}

// Get the uv of the buffer that a pixel will take from, causing the slide effect
ivec2 get_moved_uv(in ivec2 uv, in ivec2 size) {
    return wrap(uv + params.direction, size);
}

float get_brightness(in vec4 color) {
    return (color.r + color.g + color.b) / 3.0;
}

int get_frame_divisor(in float brightness) {
    brightness = pow(brightness, params.brightness_exponent);
    return params.speed_steps - max(int(ceil(params.speed_steps * min(brightness, 1.0))), 1) + 1;
}

// Get the value of the given index or give a random value if the given index value is 0
float get_value(in int index, in vec4 color, in float moved_brightness) {
    bool is_same_divisor = get_frame_divisor(get_brightness(color)) == get_frame_divisor(moved_brightness);
    return get_brightness(color) == 0.0 || !is_same_divisor ? random_in.data[index] : buffer_in.data[index];
}

void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    ivec2 size = ivec2(params.raster_size);

    if (uv.x >= size.x || uv.y >= size.y) {
        return;
    }

    ivec2 moved_uv = get_moved_uv(uv, size);
    vec4 moved_color = imageLoad(screen_image, moved_uv);
    float moved_brightness = get_brightness(moved_color);
    float value = get_value(get_buffer_index(uv, size), imageLoad(screen_image, uv), moved_brightness);
    int moved_index = get_buffer_index(moved_uv, size);
    bool is_right_frame = mod(params.frame, get_frame_divisor(moved_brightness)) == 0;
    value = moved_brightness == 0.0 || !is_right_frame ? buffer_in.data[moved_index] : value;

    buffer_out.data[moved_index] = value;
    moved_color = vec4(value, value, value, 1.0);
    imageStore(screen_image, moved_uv, moved_color);
}
