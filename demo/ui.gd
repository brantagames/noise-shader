extends Control


@export var noise_camera: Camera3D

var _effect_index: int = 1
var _is_effect_on: bool = true
var _randomize_noise_on_resize: bool = true

@onready var _compositor_effects: Array[CompositorEffect] = noise_camera.compositor.compositor_effects
@onready var _cycle_noise_effect: CyclingNoiseEffect = _compositor_effects[0]
@onready var _slide_noise_effect: SlidingNoiseEffect = _compositor_effects[1]

@onready var _effect_panels: Array[Panel] = [
	%CyclePanel,
	%SlidePanel,
]


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_effect"):
		_toggle_effect()
	elif event.is_action_pressed("toggle_auto_noise"):
		_toggle_auto_noise()
	elif event.is_action_pressed("func_clear_noise"):
		_cycle_noise_effect.clear_noise()
		_slide_noise_effect.clear_noise()
	elif event.is_action_pressed("func_randomize_noise"):
		_cycle_noise_effect.randomize_noise()
		_slide_noise_effect.randomize_noise()
	elif event.is_action_pressed("toggle_invert"):
		_slide_noise_effect.invert = not _slide_noise_effect.invert


func unfocus() -> void:
	%ShaderTypeButton.release_focus()
	%StepSlider.release_focus()
	%SpeedSlider.release_focus()
	%FramesPerUpdateSlider.release_focus()
	%XSlideSlider.release_focus()
	%YSlideSlider.release_focus()


func _on_shader_type_button_item_selected(index: int) -> void:
	_effect_index = index
	
	for panel: Panel in _effect_panels:
		panel.hide()
	_effect_panels[_effect_index].show()
	
	for effect: CompositorEffect in _compositor_effects:
		effect.enabled = false
	_compositor_effects[_effect_index].enabled = _is_effect_on


func _toggle_effect() -> void:
	_is_effect_on = not _is_effect_on
	
	var text: String = "On" if _is_effect_on else "Off"
	%CycleEffectStatus.text = text
	%SlideEffectStatus.text = text
	
	for effect: CompositorEffect in _compositor_effects:
		effect.enabled = false
	_compositor_effects[_effect_index].enabled = _is_effect_on


func _toggle_auto_noise() -> void:
	_randomize_noise_on_resize = not _randomize_noise_on_resize
	var text: String = "On" if _randomize_noise_on_resize else "Off"
	
	_cycle_noise_effect.randomize_noise_on_resize = _randomize_noise_on_resize
	_slide_noise_effect.randomize_noise_on_resize = _randomize_noise_on_resize
	
	%CycleAutoNoiseStatus.text = text
	%SlideAutoNoiseStatus.text = text


func _on_step_slider_value_changed(value: float) -> void:
	_cycle_noise_effect.steps = int(value)
	%StepLabel.text = str(int(value))


func _on_speed_slider_value_changed(value: float) -> void:
	_cycle_noise_effect.speed = value
	%SpeedLabel.text = "%.3f" % value


func _on_frames_per_update_slider_value_changed(value: int) -> void:
	_slide_noise_effect.frames_per_update = value
	%FramesPerUpdateLabel.text = str(value)


func _on_x_slide_slider_value_changed(value: int) -> void:
	_slide_noise_effect.direction.x = value
	%XSlideLabel.text = str(value)


func _on_y_slide_slider_value_changed(value: int) -> void:
	_slide_noise_effect.direction.y = value
	%YSlideLabel.text = str(value)
