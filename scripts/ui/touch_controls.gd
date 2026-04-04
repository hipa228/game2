extends Control

signal move_input_changed(direction: Vector2)
signal look_delta_changed(delta: Vector2)
signal jump_pressed
signal sprint_pressed
signal interact_pressed

@onready var left_joystick := $LeftJoystick
@onready var right_touch_area := $RightTouchArea
@onready var jump_button := $JumpButton
@onready var sprint_button := $SprintButton
@onready var interact_button := $InteractButton

var right_touch_index := -1
var right_touch_start := Vector2.ZERO

func _ready():
	# Only show on Android
	if not OS.has_feature("android"):
		visible = false
		return

	# Connect button signals
	jump_button.pressed.connect(_on_jump_pressed)
	sprint_button.pressed.connect(_on_sprint_pressed)
	interact_button.pressed.connect(_on_interact_pressed)

	# Connect joystick signal
	left_joystick.position_changed.connect(_on_left_joystick_changed)

func _input(event):
	if not OS.has_feature("android"):
		return

	if event is InputEventScreenTouch:
		_handle_touch_event(event)
	elif event is InputEventScreenDrag:
		_handle_drag_event(event)

func _handle_touch_event(event: InputEventScreenTouch):
	# Right touch area for looking
	if right_touch_area.get_global_rect().has_point(event.position):
		if event.pressed and right_touch_index == -1:
			right_touch_index = event.index
			right_touch_start = event.position
		elif not event.pressed and event.index == right_touch_index:
			right_touch_index = -1
			look_delta_changed.emit(Vector2.ZERO)

func _handle_drag_event(event: InputEventScreenDrag):
	if event.index == right_touch_index:
		var delta = event.position - right_touch_start
		right_touch_start = event.position
		look_delta_changed.emit(delta * 0.01)

func _on_left_joystick_changed(position: Vector2):
	move_input_changed.emit(position)

func _on_jump_pressed():
	jump_pressed.emit()

func _on_sprint_pressed():
	sprint_pressed.emit()

func _on_interact_pressed():
	interact_pressed.emit()

func _on_sprint_button_released():
	# Sprint is toggle or hold? We'll implement as hold
	pass

# Public methods to update button visibility
func set_button_visibility(jump: bool, sprint: bool, interact: bool):
	jump_button.visible = jump
	sprint_button.visible = sprint
	interact_button.visible = interact