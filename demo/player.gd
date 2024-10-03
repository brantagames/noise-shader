class_name Player
extends CharacterBody3D


const SPEED: float = 2.5

var noise_shader: PostProcessNoise

var sensitivity: float = 0.15

@onready var _camera_transform: Node3D = %CameraTransform
@onready var _regular_camera: Camera3D = %RegularCamera
@onready var _noise_camera: Camera3D = %NoiseCamera


func _ready() -> void:
	noise_shader = _noise_camera.compositor.compositor_effects[0]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_input_mouse_motion(event)
	elif event is InputEventMouseButton and event.is_pressed():
		DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)


func _input_mouse_motion(event: InputEventMouseMotion) -> void:
	if DisplayServer.mouse_get_mode() != DisplayServer.MOUSE_MODE_CAPTURED:
		return
	
	_camera_transform.rotation_degrees.y += -event.relative.x * sensitivity
	_camera_transform.rotation_degrees.x += -event.relative.y * sensitivity
	_camera_transform.rotation_degrees.x = clampf(
		_camera_transform.rotation_degrees.x,
		-90.0,
		90.0,
	)


func _physics_process(_delta: float) -> void:
	_move()


func _move() -> void:
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	input = input.rotated(-_camera_transform.rotation.y)
	velocity = Vector3(input.x, 0.0, input.y) * SPEED
	move_and_slide()


func _process(_delta: float) -> void:
	_update_cameras()


func _update_cameras() -> void:
	_regular_camera.global_transform = _camera_transform.global_transform
	_noise_camera.global_transform = _camera_transform.global_transform
