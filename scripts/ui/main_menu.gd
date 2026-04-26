extends Control

@onready var start_btn: Button = $StartButton
@onready var settings_btn: Button = $SettingsButton
@onready var quit_btn: Button = $QuitButton
@onready var title_label: Label = $Title
@onready var subtitle_label: Label = $Subtitle
@onready var version_label: Label = $VersionLabel
@onready var settings_panel: Control = $SettingsPanel
@onready var sens_slider: HSlider = $SettingsPanel/SensSlider
@onready var sens_label: Label = $SettingsPanel/SensValue
@onready var close_settings_btn: Button = $SettingsPanel/BackButton
@onready var menu_items: Control = $MenuItems
@onready var fade_overlay: ColorRect = $FadeOverlay

var title_glitch_timer: float = 0.0
var glitch_visible: bool = false

func _ready():
	start_btn.pressed.connect(_on_start)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)
	close_settings_btn.pressed.connect(_close_settings)
	sens_slider.value_changed.connect(_on_sens_changed)

	if SettingsManager:
		sens_slider.value = SettingsManager.mouse_sensitivity * 1000.0
		_update_sens_label(sens_slider.value)

	_style_buttons()
	_fade_in()

func _fade_in():
	fade_overlay.color = Color(0, 0, 0, 1)
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 0), 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _style_buttons():
	for btn in [start_btn, settings_btn, quit_btn]:
		var normal = StyleBoxFlat.new()
		normal.bg_color = Color(0.08, 0.08, 0.1, 0.6)
		normal.border_width_left = 1
		normal.border_width_right = 1
		normal.border_width_top = 1
		normal.border_width_bottom = 1
		normal.border_color = Color(0.6, 0.1, 0.06, 0.3)
		normal.set_corner_radius_all(4)

		var hover = StyleBoxFlat.new()
		hover.bg_color = Color(0.15, 0.05, 0.05, 0.8)
		hover.border_width_left = 1
		hover.border_width_right = 1
		hover.border_width_top = 1
		hover.border_width_bottom = 1
		hover.border_color = Color(0.8, 0.12, 0.08, 0.7)
		hover.set_corner_radius_all(4)

		var pressed = StyleBoxFlat.new()
		pressed.bg_color = Color(0.2, 0.03, 0.03, 0.9)
		pressed.border_width_left = 1
		pressed.border_width_right = 1
		pressed.border_width_top = 1
		pressed.border_width_bottom = 1
		pressed.border_color = Color(0.9, 0.15, 0.1, 0.9)
		pressed.set_corner_radius_all(4)

		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", pressed)

	# Back button in settings
	var back_normal = StyleBoxFlat.new()
	back_normal.bg_color = Color(0.1, 0.1, 0.12, 0.7)
	back_normal.border_width_left = 1
	back_normal.border_width_right = 1
	back_normal.border_width_top = 1
	back_normal.border_width_bottom = 1
	back_normal.border_color = Color(0.5, 0.08, 0.05, 0.4)
	back_normal.set_corner_radius_all(4)

	var back_hover = StyleBoxFlat.new()
	back_hover.bg_color = Color(0.18, 0.05, 0.05, 0.85)
	back_hover.border_width_left = 1
	back_hover.border_width_right = 1
	back_hover.border_width_top = 1
	back_hover.border_width_bottom = 1
	back_hover.border_color = Color(0.7, 0.1, 0.08, 0.7)
	back_hover.set_corner_radius_all(4)

	close_settings_btn.add_theme_stylebox_override("normal", back_normal)
	close_settings_btn.add_theme_stylebox_override("hover", back_hover)

func _process(delta):
	# Title subtle pulse
	var t = Time.get_ticks_msec() / 1000.0
	var pulse = 0.85 + sin(t * 0.8) * 0.15
	title_label.modulate = Color(1, pulse * 0.3, pulse * 0.2, 1)

	# Subtitle pulse
	var sub_pulse = 0.6 + sin(t * 0.5 + 1.0) * 0.2
	subtitle_label.modulate = Color(0.6, 0.55, 0.5, sub_pulse)

	# Random glitch on title
	title_glitch_timer -= delta
	if title_glitch_timer <= 0:
		if glitch_visible:
			glitch_visible = false
			title_label.position = Vector2(0, 0)
			title_glitch_timer = randf_range(3.0, 8.0)
		else:
			if randf() < 0.3:
				glitch_visible = true
				title_label.position = Vector2(randf_range(-4, 4), randf_range(-2, 2))
				title_glitch_timer = randf_range(0.05, 0.15)
			else:
				title_glitch_timer = randf_range(0.5, 2.0)

func _on_start():
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 1), 0.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_settings():
	settings_panel.show()
	menu_items.hide()

func _close_settings():
	settings_panel.hide()
	menu_items.show()
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
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 1), 0.5)
	await tween.finished
	get_tree().quit()
