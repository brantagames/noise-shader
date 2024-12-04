extends Control


@export var noise_camera: Camera3D
@export var face_light: OmniLight3D

var _effect_index: int = 1
var _is_effect_on: bool = true
var _randomize_noise_on_resize: bool = true

@onready var _compositor_effects: Array[CompositorEffect] = noise_camera.compositor.compositor_effects
@onready var _cycle_noise_effect: CyclingNoiseEffect = _compositor_effects[0]
@onready var _slide_noise_effect: SlidingNoiseEffect = _compositor_effects[1]
@onready var _color_noise_effect: ColorfulNoiseEffect = _compositor_effects[2]
@onready var _variable_slide_noise_effect: VariableSlidingNoiseEffect = _compositor_effects[3]

@onready var _effect_panels: Array[Panel] = [
	%CyclePanel,
	%SlidePanel,
	%ColorPanel,
]


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_effect"):
		_toggle_effect()
	elif event.is_action_pressed("toggle_auto_noise"):
		_toggle_auto_noise()
	elif event.is_action_pressed("func_clear_noise"):
		_cycle_noise_effect.clear_noise()
		_slide_noise_effect.clear_noise()
		_color_noise_effect.clear_noise()
		_variable_slide_noise_effect.clear_noise()
	elif event.is_action_pressed("func_randomize_noise"):
		_cycle_noise_effect.randomize_noise()
		_slide_noise_effect.randomize_noise()
		_color_noise_effect.randomize_noise()
		_variable_slide_noise_effect.randomize_noise()
	elif event.is_action_pressed("func_white_out_noise"):
		_color_noise_effect.white_out_noise()
	elif event.is_action_pressed("toggle_invert"):
		_slide_noise_effect.invert = not _slide_noise_effect.invert


func unfocus() -> void:
	%ShaderTypeButton.release_focus()
	%StepSlider.release_focus()
	%SpeedSlider.release_focus()
	%FramesPerUpdateSlider.release_focus()
	%XSlideSlider.release_focus()
	%YSlideSlider.release_focus()
	%ValueSpeedSlider.release_focus()
	%ValueSpeedSlider.release_focus()
	%HueStepSlider.release_focus()
	%HueSpeedSlider.release_focus()
	%VariableButton.release_focus()
	%SpeedStepsSlider.release_focus()


func _on_shader_type_button_item_selected(index: int) -> void:
	_effect_index = index
	
	for panel: Panel in _effect_panels:
		panel.hide()
	_effect_panels[_effect_index].show()
	
	if _effect_index == 1 and %VariableButton.button_pressed:
		_effect_index = 3
	
	if _effect_index != 3:
		%VariablePanel.hide()
	else:
		%VariablePanel.show()
	
	for effect: CompositorEffect in _compositor_effects:
		effect.enabled = false
	_compositor_effects[_effect_index].enabled = _is_effect_on


func _toggle_effect() -> void:
	_is_effect_on = not _is_effect_on
	
	var text: String = "On" if _is_effect_on else "Off"
	%CycleEffectStatus.text = text
	%SlideEffectStatus.text = text
	%ColorEffectStatus.text = text
	
	for effect: CompositorEffect in _compositor_effects:
		effect.enabled = false
	_compositor_effects[_effect_index].enabled = _is_effect_on


func _toggle_auto_noise() -> void:
	_randomize_noise_on_resize = not _randomize_noise_on_resize
	var text: String = "On" if _randomize_noise_on_resize else "Off"
	
	_cycle_noise_effect.randomize_noise_on_resize = _randomize_noise_on_resize
	_slide_noise_effect.randomize_noise_on_resize = _randomize_noise_on_resize
	_color_noise_effect.randomize_noise_on_resize = _randomize_noise_on_resize
	_variable_slide_noise_effect.randomize_noise_on_resize = _randomize_noise_on_resize
	
	%CycleAutoNoiseStatus.text = text
	%SlideAutoNoiseStatus.text = text
	%ColorAutoNoiseStatus.text = text


func _on_step_slider_value_changed(value: float) -> void:
	_cycle_noise_effect.steps = int(value)
	%StepLabel.text = str(int(value))


func _on_speed_slider_value_changed(value: float) -> void:
	_cycle_noise_effect.speed = value
	%SpeedLabel.text = "%.3f" % value


func _on_frames_per_update_slider_value_changed(value: int) -> void:
	_slide_noise_effect.frames_per_update = value
	_variable_slide_noise_effect.frames_per_update = value
	%FramesPerUpdateLabel.text = str(value)


func _on_x_slide_slider_value_changed(value: int) -> void:
	_slide_noise_effect.direction.x = value
	_variable_slide_noise_effect.direction.x = value
	%XSlideLabel.text = str(value)


func _on_y_slide_slider_value_changed(value: int) -> void:
	_slide_noise_effect.direction.y = value
	_variable_slide_noise_effect.direction.y = value
	%YSlideLabel.text = str(value)


func _on_value_step_slider_value_changed(value: int) -> void:
	_color_noise_effect.value_steps = value
	%ValueStepLabel.text = str(value)


func _on_value_speed_slider_value_changed(value: float) -> void:
	_color_noise_effect.value_speed = value
	%ValueSpeedLabel.text = str(value)


func _on_hue_step_slider_value_changed(value: int) -> void:
	_color_noise_effect.hue_steps = value
	%HueStepLabel.text = str(value)


func _on_hue_speed_slider_value_changed(value: float) -> void:
	_color_noise_effect.hue_speed = value
	%HueSpeedLabel.text = str(value)


func _on_hue_offset_slider_value_changed(value: float) -> void:
	_color_noise_effect.hue_offset = value
	%HueOffsetLabel.text = str(value)


func _on_variable_button_toggled(toggled_on: bool) -> void:
	%VariablePanel.visible = toggled_on
	_effect_index = 1 if not toggled_on else 3
	
	if not _is_effect_on:
		return
	
	if toggled_on:
		_slide_noise_effect.enabled = false
		_variable_slide_noise_effect.enabled = true
	else:
		_slide_noise_effect.enabled = true
		_variable_slide_noise_effect.enabled = false


func _on_speed_steps_slider_value_changed(value: int) -> void:
	_variable_slide_noise_effect.speed_steps = value
	%SpeedStepLabel.text = str(value)


func _on_brightness_exponent_slider_value_changed(value: float) -> void:
	_variable_slide_noise_effect.brightness_exponent = value
	%BrightnessExponentLabel.text = "%1.2f" % value


func _on_light_attenuation_slider_value_changed(value: float) -> void:
	face_light.omni_attenuation = value
	%LightAttenuationLabel.text = "%1.2f" % value
