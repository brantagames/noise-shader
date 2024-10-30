extends CompositorEffect
class_name SlidingNoiseEffect
## Adds a noisy effect to a camera.


const NOISE_SHADER_PATH: String = "res://addons/noise_shader/sliding_noise.glsl"
const BYTES_PER_BUFFER_FLOAT: int = 4

@export_group("Parameters")
## If true, it randomizes each pixel every time the window is updated.
@export var randomize_noise_on_resize: bool = true
## The direction the noise slides
@export var direction: Vector2i = Vector2i.DOWN
## Determines which part of the image slides
@export var invert: bool = false
## How many frames happen per update. Higher numbers make the sliding slower
@export_range(1, 60) var frames_per_update: int = 1:
	set(value):
		frames_per_update = maxi(value, 1)

var _frame: int = 1

var _rendering_device: RenderingDevice
var _shader: RID
var _pipeline: RID

var _buffer_size: int = 512 * 512 * BYTES_PER_BUFFER_FLOAT

var _read_data: PackedByteArray = []
var _write_data: PackedByteArray = []
var _random_data: PackedByteArray = []
var _read_buffer: RID
var _write_buffer: RID
var _random_buffer: RID

var _storage_set: RID


func _init() -> void:
	effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	_rendering_device = RenderingServer.get_rendering_device()
	RenderingServer.call_on_render_thread(_initialize_compute)


## Assigns a random value to each pixel of the noise.
func randomize_noise() -> void:
	_randomize_data(_write_data)
	_randomize_data(_read_data)


## Assigns a value of 0.0 to each pixel of the noise.
func clear_noise() -> void:
	for offset: int in range(0, _write_data.size(), 4):
		_write_data.encode_float(offset, 0.0)
	for offset: int in range(0, _read_data.size(), 4):
		_read_data.encode_float(offset, 0.0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if _shader.is_valid():
			RenderingServer.free_rid(_shader)


func _initialize_compute() -> void:
	_rendering_device = RenderingServer.get_rendering_device()
	if not _rendering_device:
		return
	
	var shader_file: RDShaderFile = load(NOISE_SHADER_PATH)
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	
	_shader = _rendering_device.shader_create_from_spirv(shader_spirv)
	if not _shader.is_valid():
		return
	
	_update_storage_set()
	
	_pipeline = _rendering_device.compute_pipeline_create(_shader)


func _render_callback(effect_callback_type: int, render_data: RenderData) -> void:
	if (
			not _rendering_device
			or effect_callback_type != EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
			or not _pipeline.is_valid()
	):
		return
	
	var render_scene_buffers: RenderSceneBuffersRD = render_data.get_render_scene_buffers()
	if not render_scene_buffers:
		return
	
	var size: Vector2i = render_scene_buffers.get_internal_size()
	if size.x == 0 and size.y == 0:
		return
	
	if not _buffer_size == size.x * size.y * BYTES_PER_BUFFER_FLOAT:
		_buffer_size = size.x * size.y * BYTES_PER_BUFFER_FLOAT
		_update_storage_set()
	
	@warning_ignore("integer_division")
	var x_groups: int = (size.x - 1) / 8 + 1
	@warning_ignore("integer_division")
	var y_groups: int = (size.y - 1) / 8 + 1
	var z_groups: int = 1
	
	var update: bool = false
	if _frame % frames_per_update == 0:
		update = true
		_frame = 1
	else:
		_frame += 1
	
	var push_constant: PackedByteArray = _get_push_constant(size, update)
	
	# instead of randomizing each individual element, we can just shuffle the random array around
	# this performs much better
	var shuffle_data: Array = Array(_random_data.to_float32_array())
	shuffle_data.shuffle()
	_random_data = PackedFloat32Array(shuffle_data).to_byte_array()
	#_randomize_data(_random_data)
	
	_rendering_device.buffer_update(_random_buffer, 0, _buffer_size, _random_data)
	_rendering_device.buffer_update(_read_buffer, 0, _buffer_size, _read_data)
	
	for view_index: int in render_scene_buffers.get_view_count():
		var screen_image := RDUniform.new()
		screen_image.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		screen_image.binding = 0
		var input_image: RID = render_scene_buffers.get_color_layer(view_index)
		screen_image.add_id(input_image)
		
		var screen_set: RID = UniformSetCacheRD.get_cache(
			_shader,
			0, 
			[screen_image],
		)
		
		var compute_list: int = _rendering_device.compute_list_begin()
		_rendering_device.compute_list_bind_compute_pipeline(compute_list, _pipeline)
		_rendering_device.compute_list_bind_uniform_set(compute_list, screen_set, 0)
		_rendering_device.compute_list_bind_uniform_set(compute_list, _storage_set, 1)
		_rendering_device.compute_list_set_push_constant(
			compute_list,
			push_constant,
			push_constant.size(),
		)
		_rendering_device.compute_list_dispatch(compute_list, x_groups, y_groups, z_groups)
		_rendering_device.compute_list_end()
	
	# This takes the output of the shader and puts it into the input.
	_read_data = _rendering_device.buffer_get_data(_write_buffer)


func _get_push_constant(size: Vector2, do_update: bool) -> PackedByteArray:
	var push_constant: PackedByteArray = []
	push_constant.resize(32)
	push_constant.encode_float(0, size.x)
	push_constant.encode_float(4, size.y)
	push_constant.encode_s32(8, direction.x * int(do_update))
	push_constant.encode_s32(12, direction.y * int(do_update))
	push_constant.encode_s32(16, int(invert))
	return push_constant


func _update_storage_set() -> void:
	_read_data.resize(_buffer_size)
	_write_data.resize(_buffer_size)
	_random_data.resize(_buffer_size)
	
	if randomize_noise_on_resize:
		randomize_noise()
	
	var buffer_in := RDUniform.new()
	buffer_in.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	buffer_in.binding = 1
	_read_buffer = _rendering_device.storage_buffer_create(_buffer_size, _read_data)
	buffer_in.add_id(_read_buffer)
	
	var buffer_out := RDUniform.new()
	buffer_out.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	buffer_out.binding = 2
	_write_buffer = _rendering_device.storage_buffer_create(_buffer_size, _write_data)
	buffer_out.add_id(_write_buffer)
	
	var random_in := RDUniform.new()
	random_in.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	random_in.binding = 3
	_randomize_data(_random_data)
	_random_buffer = _rendering_device.storage_buffer_create(_buffer_size, _random_data)
	random_in.add_id(_random_buffer)
	
	_storage_set = _rendering_device.uniform_set_create(
		[buffer_in, buffer_out, random_in],
		_shader,
		1,
	)


func _randomize_data(data: PackedByteArray) -> void:
	for offset: int in range(0, data.size(), 4):
		data.encode_float(offset, randf())
