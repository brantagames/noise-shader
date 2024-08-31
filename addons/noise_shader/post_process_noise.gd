extends CompositorEffect
class_name PostProcessNoise


const NOISE_SHADER_PATH: String = "res://addons/noise_shader/noise.glsl"
const BYTES_PER_BUFFER_FLOAT: int = 4

@export_group("Parameters")
## If true, it randomizes each pixel every time the window is updated.
@export var add_random_noise: bool = false
## How many different colors there are.
@export var steps: int = 3:
	set(value):
		steps = maxi(value, 2)
## How fast each pixel of the noise is cycled through.
@export var speed: float = 0.2:
	set(value):
		speed = clampf(value, 0.0, 1.0)

var _huh: int = 0

var _rendering_device: RenderingDevice
var _shader: RID
var _pipeline: RID

var _buffer_size: int = 512 * 512 * BYTES_PER_BUFFER_FLOAT

var _read_buffer: RID
var _write_buffer: RID

var _read_data: PackedByteArray = []
var _write_data: PackedByteArray = []

var _storage_set: RID


func _init() -> void:
	effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	_rendering_device = RenderingServer.get_rendering_device()
	RenderingServer.call_on_render_thread(_initialize_compute)


## Assigns a random value to each pixel of the noise.
func randomize_noise() -> void:
	for offset: int in range(0, _write_data.size(), 4):
		_write_data.encode_float(offset, randf())
	for offset: int in range(0, _read_data.size(), 4):
		_read_data.encode_float(offset, randf())


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
	
	var push_constant: PackedByteArray
	push_constant.append_array(PackedFloat32Array([
		size.x,
		size.y,
		0.0,
		0.0,
	]).to_byte_array())
	push_constant.append_array(PackedInt32Array([steps]).to_byte_array())
	push_constant.append_array(PackedFloat32Array([speed]).to_byte_array())
	push_constant.resize(32)
	
	_rendering_device.buffer_update(_read_buffer, 0, _buffer_size, _read_data)
	
	var view_count: int = render_scene_buffers.get_view_count()
	for view_index: int in view_count:
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
	
	_read_data = _rendering_device.buffer_get_data(_write_buffer)


func _update_storage_set() -> void:
	_read_data.resize(_buffer_size)
	_write_data.resize(_buffer_size)
	
	if add_random_noise:
		for offset: int in range(0, _write_data.size(), 4):
			_write_data.encode_float(offset, randf())
		for offset: int in range(0, _read_data.size(), 4):
			_read_data.encode_float(offset, randf())
	
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
	
	_storage_set = _rendering_device.uniform_set_create(
		[buffer_in, buffer_out],
		_shader,
		1,
	)
