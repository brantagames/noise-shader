#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D screen_image;

// Details parameters to be sent to the shader
layout(push_constant, std430) uniform Params {
    vec2 raster_size;
    ivec2 direction;
    bool invert;
    int speed_steps;
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

int get_speed(in float brightness) {
    return max(int(ceil(params.speed_steps * sqrt(brightness))), 1);
}

// Get the uv of the buffer that a pixel will take from, causing the slide effect
ivec2 get_moved_uv(in ivec2 uv, in ivec2 size, in float brightness) {
    return wrap(uv + -params.direction * get_speed(brightness), size);
    //return wrap(uv + -params.direction, size);
}

float get_brightness(in vec4 color) {
    return min((color.r + color.g + color.b) / 3.0, 1.0);
}

bool is_bright(in vec4 color) {
    return (get_brightness(color) == 0.0) != params.invert;
}

// Get the value of the given index or give a random value if the given index value is 0
float get_value(in int index, in vec4 color, in float comparison_brightness) {
    bool is_same_rate = get_speed(get_brightness(color)) == get_speed(comparison_brightness);
    return is_bright(color) || !is_same_rate ? random_in.data[index] : buffer_in.data[index];
}

void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    ivec2 size = ivec2(params.raster_size);

    if (uv.x >= size.x || uv.y >= size.y) {
        return;
    }

    vec4 color = imageLoad(screen_image, uv);
    ivec2 moved_uv = get_moved_uv(uv, size, get_brightness(color));
    float moved_value = get_value(
        get_buffer_index(moved_uv, size),
        imageLoad(screen_image, moved_uv),
        get_brightness(color));

    int index = get_buffer_index(uv, size);
    float value = buffer_in.data[index];
    value = is_bright(color) ? buffer_in.data[index] : moved_value;

    buffer_out.data[index] = value;
    color = vec4(value, value, value, 1.0);
    imageStore(screen_image, uv, color);
}
