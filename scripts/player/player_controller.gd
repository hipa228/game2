extends CharacterBody3D

# Player movement parameters
@export var speed : float = 5.0
@export var sprint_speed : float = 8.0
@export var jump_velocity : float = 4.5
@export var mouse_sensitivity : float = 0.002
@export var acceleration : float = 10.0
@export var air_acceleration : float = 2.0

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_speed : float = speed
var is_sprinting : bool = false

# Camera nodes
@onready var camera : Camera3D = $Camera3D
@onready var head : Node3D = $Head

# Touch controls for Android
var touch_delta : Vector2 = Vector2.ZERO
var move_input : Vector2 = Vector2.ZERO
var touch_controls: Node = null

func _ready():
	# Hide mouse cursor and capture it
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Connect to touch events for Android
	if OS.has_feature("android"):
		_setup_touch_controls()

func _setup_touch_controls():
	# Find touch controls in scene
	var touch_nodes = get_tree().get_nodes_in_group("touch_controls")
	if touch_nodes.size() > 0:
		touch_controls = touch_nodes[0]
		if touch_controls.has_signal("move_input_changed"):
			touch_controls.move_input_changed.connect(set_move_input)
		if touch_controls.has_signal("look_delta_changed"):
			touch_controls.look_delta_changed.connect(set_look_delta)
		if touch_controls.has_signal("jump_pressed"):
			touch_controls.jump_pressed.connect(_on_touch_jump)
		if touch_controls.has_signal("sprint_pressed"):
			touch_controls.sprint_pressed.connect(_on_touch_sprint)
		if touch_controls.has_signal("interact_pressed"):
			touch_controls.interact_pressed.connect(_on_touch_interact)

func _input(event):
	# Mouse look for desktop
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		head.rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

	# Touch input for Android
	if OS.has_feature("android") and event is InputEventScreenDrag:
		# Right side of screen for looking
		if event.position.x > get_viewport().size.x * 0.5:
			head.rotate_y(-event.relative.x * mouse_sensitivity * 0.5)
			camera.rotate_x(-event.relative.y * mouse_sensitivity * 0.5)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

	# Escape key to show/hide mouse
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(_delta):
	# Handle sprint input
	is_sprinting = Input.is_action_pressed("sprint")
	current_speed = sprint_speed if is_sprinting else speed

	# Update HUD (if any)
	_update_hud()

func _update_hud():
	# Update speed indicator, health, etc.
	pass

func _physics_process(delta):
	# Add the gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get input direction
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	# For Android touch controls, blend with touch input
	if OS.has_feature("android"):
		input_dir = input_dir + move_input
		input_dir = input_dir.limit_length(1.0)

	# Transform input direction to world space
	var direction := (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Apply movement
	if direction:
		var target_velocity = direction * current_speed
		var accel = acceleration if is_on_floor() else air_acceleration
		velocity.x = lerp(velocity.x, target_velocity.x, accel * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, accel * delta)
	else:
		# Apply friction when no input
		var accel = acceleration if is_on_floor() else air_acceleration
		velocity.x = lerp(velocity.x, 0.0, accel * delta)
		velocity.z = lerp(velocity.z, 0.0, accel * delta)

	move_and_slide()

	# Footstep sounds (placeholder)
	if is_on_floor() and (velocity.x != 0 or velocity.z != 0):
		_play_footstep_sound(delta)

func _play_footstep_sound(delta):
	# Implement footstep sound timing
	pass

func take_damage(amount: float):
	# Implement health system
	pass

func die():
	# Implement death sequence
	get_tree().reload_current_scene()

# Public method for touch controls
func set_move_input(input: Vector2):
	move_input = input

func set_look_delta(delta: Vector2):
	if delta.length() > 0:
		head.rotate_y(-delta.x * mouse_sensitivity * 0.5)
		camera.rotate_x(-delta.y * mouse_sensitivity * 0.5)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _on_touch_jump():
	# Simulate jump input for next physics frame
	Input.action_press("jump")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("jump")

func _on_touch_sprint():
	is_sprinting = true

func _on_touch_interact():
	Input.action_press("interact")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("interact")