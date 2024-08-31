#[compute]
#version 450

#define STEPS 3

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D screen_image;

layout(push_constant, std430) uniform Params {
    vec2 raster_size;
    vec2 reserved;
    int steps;
    float speed;
} params;

layout(set = 1, binding = 1, std430) restrict buffer FloatBufferIn {
  float data[];
}
buffer_in;

layout(set = 1, binding = 2, std430) restrict buffer FloatBufferOut {
  float data[];
}
buffer_out;

int get_buffer_index(in ivec2 uv, in ivec2 size) {
    return uv.y * size.x + uv.x;
}

void update_value(inout float value, in vec4 screen_color) {
    value = value + clamp(screen_color.r, 0.0, 1.0) * params.speed;
    value -= floor(value);
}

float get_brightness_from_value(in float value) {
    float brightness = floor(value * 2.0 * float(params.steps - 1));
    brightness = float(params.steps - 1) - abs(brightness - float(params.steps - 1));
    return brightness / float(params.steps - 1);
}

void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    ivec2 size = ivec2(params.raster_size);

    if (uv.x >= size.x || uv.y >= size.y) {
        return;
    }

    int index = get_buffer_index(uv, size);
    float value = buffer_in.data[index];
    vec4 screen_color = imageLoad(screen_image, uv);

    update_value(value, screen_color);
    buffer_out.data[index] = value;

    screen_color.rgb = vec3(pow(get_brightness_from_value(value), 3.0));
    imageStore(screen_image, uv, screen_color);
}
