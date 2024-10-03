extends Control


@export var player: Player

@onready var _effect_status: Label = %EffectStatus
@onready var _auto_noise_status: Label = %AutoNoiseStatus


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_effect"):
		_toggle_effect()
	elif event.is_action_pressed("toggle_auto_noise"):
		_toggle_auto_noise()
	elif event.is_action_pressed("func_clear_noise"):
		player.noise_shader.clear_noise()
	elif event.is_action_pressed("func_randomize_noise"):
		player.noise_shader.randomize_noise()


func _toggle_effect() -> void:
	player.noise_shader.enabled = not player.noise_shader.enabled
	_effect_status.text = "On" if player.noise_shader.enabled else "Off"


func _toggle_auto_noise() -> void:
	player.noise_shader.automatically_apply_noise = not player.noise_shader.automatically_apply_noise
	_auto_noise_status.text = "On" if player.noise_shader.automatically_apply_noise else "Off"


func _on_step_slider_value_changed(value: float) -> void:
	player.noise_shader.steps = int(value)
	%StepLabel.text = str(int(value))


func _on_speed_slider_value_changed(value: float) -> void:
	player.noise_shader.speed = value
	%SpeedLabel.text = "%.3f" % value
