extends Control

@onready var start_btn: Button = $StartButton
@onready var settings_btn: Button = $SettingsButton
@onready var quit_btn: Button = $QuitButton
@onready var title: Label = $Title
@onready var settings_panel: Control = $SettingsPanel
@onready var sens_slider: HSlider = $SettingsPanel/SensSlider
@onready var sens_label: Label = $SettingsPanel/SensValue
@onready var close_settings_btn: Button = $SettingsPanel/BackButton

var title_pulse := 0.0

func _ready():
	start_btn.pressed.connect(_on_start)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)
	close_settings_btn.pressed.connect(_close_settings)
	sens_slider.value_changed.connect(_on_sens_changed)

	if SettingsManager:
		sens_slider.value = SettingsManager.mouse_sensitivity * 1000.0
		_update_sens_label(sens_slider.value)

func _process(delta):
	title_pulse += delta * 1.2
	var alpha = 0.85 + sin(title_pulse) * 0.15
	var c = title.theme_override_colors.font_color
	title.theme_override_colors.font_color = Color(c.r, c.g, c.b, alpha)

func _on_start():
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_settings():
	settings_panel.show()
	start_btn.hide()
	settings_btn.hide()
	quit_btn.hide()

func _close_settings():
	settings_panel.hide()
	start_btn.show()
	settings_btn.show()
	quit_btn.show()
	if SettingsManager:
		SettingsManager.save_settings()

func _on_sens_changed(value: float):
	var sens = value / 1000.0
	if SettingsManager:
		SettingsManager.mouse_sensitivity = sens
	_update_sens_label(value)

func _update_sens_label(value: float):
	sens_label.text = str(snapped(value / 10.0, 0.1))

func _on_quit():
	get_tree().quit()
