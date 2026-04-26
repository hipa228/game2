extends Control

signal move_input_changed(direction: Vector2)
signal look_delta_changed(delta: Vector2)
signal flashlight_pressed
signal interact_pressed
signal jump_pressed
signal crouch_pressed

# Configuration
@export var deadzone_radius : float = 10.0
@export var look_sensitivity : float = 1.0

@onready var joystick := $Joystick
@onready var joystick_handle := $Joystick/JoystickHandle
@onready var look_area := $LookArea
@onready var flashlight_button := $FlashlightButton
@onready var interact_button := $InteractButton
@onready var jump_button := $JumpButton
@onready var crouch_button := $CrouchButton
@onready var battery_fill := $BatteryBar/BatteryFill
@onready var clock_label := $ClockLabel

var joystick_active := false
var joystick_touch_index : int = -1
var joystick_center := Vector2.ZERO
var joystick_max_distance := 120.0
var joystick_default_color := Color(1, 1, 1, 0.2)
var joystick_active_color := Color(0.8, 0.8, 1.0, 0.4)

var look_touch_index : int = -1
var look_touch_start : Vector2 = Vector2.ZERO

func _ready():
	if not OS.has_feature("android") and not OS.has_feature("mobile"):
		visible = false
		return

	flashlight_button.pressed.connect(_on_flashlight_pressed)
	interact_button.pressed.connect(_on_interact_pressed)
	jump_button.pressed.connect(_on_jump_pressed)
	crouch_button.pressed.connect(_on_crouch_pressed)
	_style_buttons()
	call_deferred("_make_buttons_square")

	joystick_center = joystick_handle.position + joystick_handle.size / 2
	joystick_handle.color = joystick_default_color

func _make_buttons_square():
	# Make buttons square for perfect circles
	for btn in [crouch_button, jump_button, interact_button, flashlight_button]:
		if not btn or not is_instance_valid(btn):
			continue
		var s = mini(int(btn.size.x), int(btn.size.y))
		if s > 10:
			btn.size = Vector2(s, s)

func _is_on_button(touch_pos: Vector2) -> bool:
	return (flashlight_button.get_global_rect().has_point(touch_pos)
		or interact_button.get_global_rect().has_point(touch_pos)
		or jump_button.get_global_rect().has_point(touch_pos)
		or crouch_button.get_global_rect().has_point(touch_pos))

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			# Touch-down: activate joystick or look area by position
			if joystick.get_global_rect().has_point(event.position):
				if joystick_touch_index == -1:
					joystick_active = true
					joystick_touch_index = event.index
					_update_joystick(event.position)
			elif look_area.get_global_rect().has_point(event.position) \
			and not _is_on_button(event.position) \
			and event.index != joystick_touch_index:
				if look_touch_index == -1:
					look_touch_index = event.index
					look_touch_start = event.position
		else:
			# Touch-up: release by finger index, not position
			if event.index == joystick_touch_index:
				joystick_active = false
				joystick_touch_index = -1
				_reset_joystick()
			if event.index == look_touch_index:
				look_touch_index = -1
				look_delta_changed.emit(Vector2.ZERO)

	elif event is InputEventScreenDrag:
		if joystick_active and event.index == joystick_touch_index:
			_update_joystick(event.position)

		if event.index == look_touch_index and not _is_on_button(event.position):
			var delta = event.position - look_touch_start
			look_touch_start = event.position
			if delta.length() > 2.0:
				look_delta_changed.emit(delta * look_sensitivity * 0.005)

func _update_joystick(touch_pos: Vector2):
	var local_pos = touch_pos - joystick.global_position
	var direction = (local_pos - joystick_center)

	if direction.length() > joystick_max_distance:
		direction = direction.normalized() * joystick_max_distance

	joystick_handle.position = joystick_center + direction - (joystick_handle.size / 2)
	joystick_handle.color = joystick_active_color

	# Apply deadzone to input
	var input_vec = Vector2.ZERO
	var distance = direction.length()
	if distance > deadzone_radius:
		var scaled_distance = (distance - deadzone_radius) / (joystick_max_distance - deadzone_radius)
		input_vec = direction.normalized() * scaled_distance
	move_input_changed.emit(Vector2(input_vec.x, input_vec.y))

func _reset_joystick():
	joystick_handle.position = joystick_center - (joystick_handle.size / 2)
	joystick_handle.color = joystick_default_color
	move_input_changed.emit(Vector2.ZERO)

func set_battery(percent: float):
	if not battery_fill:
		return
	battery_fill.anchor_right = 0.02 + 0.94 * percent
	if percent > 0.5:
		battery_fill.color = Color(0.2, 0.9, 0.2, 1)
	elif percent > 0.25:
		battery_fill.color = Color(0.9, 0.8, 0.1, 1)
	else:
		battery_fill.color = Color(0.9, 0.2, 0.1, 1)

func set_time(hour: int, minute: int):
	if not clock_label:
		return
	clock_label.text = "%02d:%02d" % [hour, minute]

func _on_flashlight_pressed():
	flashlight_pressed.emit()

func _on_interact_pressed():
	interact_pressed.emit()

func _on_jump_pressed():
	jump_pressed.emit()

func _on_crouch_pressed():
	crouch_pressed.emit()

func _style_buttons():
	for btn in [flashlight_button, interact_button, jump_button, crouch_button]:
		# Normal state - dark circle with subtle border
		var normal = StyleBoxFlat.new()
		normal.bg_color = Color(0, 0, 0, 0.4)
		normal.set_corner_radius_all(50)
		normal.border_width_all = 2
		normal.border_color = Color(1, 1, 1, 0.2)

		# Hover state - slightly brighter
		var hover = StyleBoxFlat.new()
		hover.bg_color = Color(0, 0, 0, 0.5)
		hover.set_corner_radius_all(50)
		hover.border_width_all = 2
		hover.border_color = Color(1, 1, 1, 0.3)

		# Pressed state - light background
		var pressed = StyleBoxFlat.new()
		pressed.bg_color = Color(1, 1, 1, 0.3)
		pressed.set_corner_radius_all(50)
		pressed.border_width_all = 2
		pressed.border_color = Color(1, 1, 1, 0.5)

		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", pressed)

		btn.add_theme_font_size_override("font_size", 30)
		btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
		btn.add_theme_color_override("font_pressed_color", Color(0, 0, 0, 0.7))
		btn.add_theme_constant_override("outline_size", 2)
		btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))

	# Style main buttons (crouch, jump) with a slightly different border
	for btn in [crouch_button, jump_button]:
		# Make the border more visible for main buttons
		var normal = StyleBoxFlat.new()
		normal.bg_color = Color(0, 0, 0, 0.4)
		normal.set_corner_radius_all(50)
		normal.border_width_all = 2
		normal.border_color = Color(1, 1, 1, 0.3)

		var pressed = StyleBoxFlat.new()
		pressed.bg_color = Color(1, 1, 1, 0.3)
		pressed.set_corner_radius_all(50)
		pressed.border_width_all = 2
		pressed.border_color = Color(1, 1, 1, 0.5)

		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", normal)
		btn.add_theme_stylebox_override("pressed", pressed)
