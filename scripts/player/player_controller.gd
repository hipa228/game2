extends CharacterBody3D

# Player movement parameters
@export var speed : float = 5.5
@export var sprint_speed : float = 8.5
@export var jump_velocity : float = 5.0
@export var mouse_sensitivity : float = 0.003
@export var acceleration : float = 25.0
@export var air_acceleration : float = 6.0
@export var deceleration : float = 30.0
@export var crouch_speed : float = 2.5

# Crouch system
var is_crouching : bool = false
var head_normal_pos : Vector3

# Battery system
@export var battery_max : float = 100.0
@export var battery_drain_rate : float = 0.5  # per second
@export var battery_low_threshold : float = 20.0
@export var battery_critical_threshold : float = 5.0
var battery_level : float = 100.0

# Key system
var has_key : bool = false

# OP mechanics
var speed_boost_timer : float = 0.0
var overcharge_timer : float = 0.0

# Sanity system
var sanity_level : float = 100.0
var sanity_drain_rate : float = 2.0  # per second in darkness

# Gravity
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity_scale : float = 1.0
var current_speed : float = speed
var is_sprinting : bool = false

# Camera
@onready var camera : Camera3D = $Head/Camera3D
@onready var head : Node3D = $Head

# Head bobbing
var bob_timer : float = 0.0
var bob_intensity : float = 0.0
const BOB_FREQ_WALK : float = 10.0
const BOB_FREQ_SPRINT : float = 14.0
const BOB_AMP_WALK : float = 0.0008
const BOB_AMP_SPRINT : float = 0.0015
var head_rest_pos : Vector3

# Flashlight
@onready var flashlight_light : SpotLight3D = $Head/Camera3D/FlashlightLight
var flashlight_enabled : bool = true
var flicker_timer : float = 0.0
var base_light_energy : float = 6.0

# Touch controls
@export var touch_sensitivity : float = 1.0
var move_input : Vector2 = Vector2.ZERO
var touch_controls: Node = null

# Hiding
var is_hiding : bool = false
var unhide_pos : Vector3
var near_wardrobe : bool = false
var near_terminal: bool = false
var near_exit_door: bool = false
var near_color_puzzle: bool = false
var in_terminal_mode: bool = false

# Furniture search cooldowns (node path -> seconds remaining)
var search_cooldowns: Dictionary = {}
const SEARCH_COOLDOWN_TIME: float = 20.0
const SEARCH_BATTERY_CHANCE: float = 0.5
const SEARCH_BATTERY_AMOUNT: float = 25.0

# Survival timer (survive until 6 AM)
var game_time: float = 0.0
const GAME_TIME_SCALE: float = 60.0
const START_HOUR: int = 23
const START_MINUTE: int = 0
const SURVIVAL_TIME: float = 7.0 * 3600.0  # 7 game hours = 25200 game seconds
var game_won: bool = false

func _ready():
	if SettingsManager:
		mouse_sensitivity = SettingsManager.mouse_sensitivity
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if OS.has_feature("android"):
		_setup_touch_controls()

	if flashlight_light:
		flashlight_light.visible = flashlight_enabled

		head_rest_pos = head.position
	head_normal_pos = head.position

func _setup_touch_controls():
	var touch_nodes = get_tree().get_nodes_in_group("touch_controls")
	if touch_nodes.size() > 0:
		touch_controls = touch_nodes[0]
		if touch_controls.has_signal("move_input_changed"):
			touch_controls.move_input_changed.connect(set_move_input)
		if touch_controls.has_signal("look_delta_changed"):
			touch_controls.look_delta_changed.connect(set_look_delta)
		if touch_controls.has_signal("flashlight_pressed"):
			touch_controls.flashlight_pressed.connect(_on_touch_flashlight)
		if touch_controls.has_signal("interact_pressed"):
			touch_controls.interact_pressed.connect(_on_interact)
		if touch_controls.has_signal("jump_pressed"):
			touch_controls.jump_pressed.connect(_on_touch_jump)
		if touch_controls.has_signal("crouch_pressed"):
			touch_controls.crouch_pressed.connect(_on_touch_crouch)

func _input(event):
	if not camera or not head:
		return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED \
	and not OS.has_feature("android"):
		head.rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	# Survival timer - один раз для всех режимов
	if not game_won:
		game_time += delta * GAME_TIME_SCALE
		if game_time >= SURVIVAL_TIME:
			game_won = true
			_win_game()
			return

	if in_terminal_mode:
		_update_hud()
		return



	is_sprinting = Input.is_action_pressed("sprint") and not is_crouching
	current_speed = crouch_speed if is_crouching else (sprint_speed if is_sprinting else speed)

	if Input.is_action_just_pressed("flashlight"):
		if not in_terminal_mode:
			toggle_flashlight()

	if Input.is_action_just_pressed("interact"):
		_on_interact()

	_check_wardrobe_proximity()
	_check_terminal_proximity()
	_check_color_puzzle_proximity()
	_check_door_proximity()
	_update_battery(delta)
	_update_flashlight_visuals(delta)
	_update_sanity(delta)
	_check_pickups()
	_update_op_mechanics(delta)

	# Head bobbing
	var velocity_len = Vector3(velocity.x, 0, velocity.z).length()
	if velocity_len > 0.1 and not is_hiding:
		var bob_freq = BOB_FREQ_SPRINT if is_sprinting else BOB_FREQ_WALK
		var bob_amp = BOB_AMP_SPRINT if is_sprinting else BOB_AMP_WALK
		bob_timer += delta * velocity_len * bob_freq
		var bob_offset = sin(bob_timer) * bob_amp
		head.position.y = head_rest_pos.y - (0.4 if is_crouching else 0.0) + bob_offset
	else:
		bob_timer = 0.0
		# Smooth return to rest
		head.position.y = lerp(head.position.y, head_rest_pos.y - (0.4 if is_crouching else 0.0), delta * 10.0)


	# Decrement search cooldowns
	for key in search_cooldowns.keys():
		search_cooldowns[key] -= delta
		if search_cooldowns[key] <= 0:
			search_cooldowns.erase(key)

	_update_hud()

func _update_battery(delta):
	if flashlight_enabled and battery_level > 0:
		# No drain during overcharge
		if overcharge_timer <= 0:
			battery_level = max(0, battery_level - battery_drain_rate * delta)
		if battery_level <= 0:
			toggle_flashlight()

func _update_flashlight_visuals(delta):
	if not flashlight_light or not flashlight_enabled:
		return

	# Overcharge skips normal visuals (handled in _update_op_mechanics)
	if overcharge_timer > 0:
		return

	var intensity = 1.0

	if battery_level <= battery_critical_threshold:
		intensity = 0.1
	elif battery_level <= battery_low_threshold:
		intensity = 0.2 + 0.3 * (battery_level / battery_low_threshold)
	else:
		intensity = 0.7 + 0.3 * (battery_level / battery_max)

	# Flicker effect
	if battery_level < battery_low_threshold:
		flicker_timer += delta
		if flicker_timer > 0.1 + battery_level * 0.02:
			var flicker = 0.7 + randf() * 0.3
			intensity *= flicker
			flicker_timer = 0.0

	flashlight_light.light_energy = base_light_energy * intensity

func _update_sanity(delta):
	if not flashlight_enabled or battery_level <= battery_critical_threshold:
		sanity_level = max(0, sanity_level - sanity_drain_rate * delta)
	else:
		sanity_level = min(100, sanity_level + 1.0 * delta)

func _check_pickups():
	var player_pos = global_position

	# Check battery pickups
	var battery_areas = get_tree().get_nodes_in_group("battery_pickup")
	for area in battery_areas:
		if area and is_instance_valid(area):
			var dist = player_pos.distance_to(area.global_position)
			if dist < 0.6:
				# OP: Speed boost if picking up at high charge (>75%)
				if battery_level > 75.0:
					speed_boost_timer = 5.0
					print("[OP] Speed boost activated! 5 seconds of +60% speed!")

				# OP: Overcharge if picking up at critical charge (<5%)
				if battery_level < 5.0:
					overcharge_timer = 3.0
					print("[OP] Overcharge! 3 seconds of infinite flashlight!")

				battery_level = min(battery_max, battery_level + 50.0)
				area.queue_free()


func _update_op_mechanics(delta):
	# Speed boost: +60% sprint speed for 5 seconds
	if speed_boost_timer > 0:
		speed_boost_timer -= delta
		sprint_speed = 13.5  # base is 8.5
		if speed_boost_timer <= 0:
			sprint_speed = 8.5
			print("[OP] Speed boost ended")

	# Overcharge: infinite flashlight, no drain, extra bright for 3 seconds
	if overcharge_timer > 0:
		overcharge_timer -= delta
		if overcharge_timer > 0 and flashlight_light:
			flashlight_light.light_energy = base_light_energy * 2.0  # extra bright

func _check_wardrobe_proximity():
	near_wardrobe = false
	var hide_areas = get_tree().get_nodes_in_group("wardrobe_hide")
	for hide_area in hide_areas:
		if is_instance_valid(hide_area):
			var dist = global_position.distance_to(hide_area.global_position)
			if dist < 2.0:
				near_wardrobe = true
				return

func _toggle_hide():
	if in_terminal_mode:
		return
	if is_hiding:
		# Exit animation
		if camera:
			var tween_out = create_tween()
			tween_out.tween_property(camera, "position", Vector3.ZERO, 0.15).set_ease(Tween.EASE_OUT)
		# Open wardrobe doors
		var doors = get_tree().get_nodes_in_group("wardrobe_door")
		for door in doors:
			var tween_door = create_tween()
			tween_door.tween_property(door, "rotation:y", 0.0, 0.2).set_ease(Tween.EASE_OUT)
		# Restore position
		await get_tree().create_timer(0.15).timeout
		is_hiding = false
		global_position = unhide_pos
		# Re-enable flashlight if it was on
		if flashlight_light and not flashlight_light.visible:
			flashlight_light.visible = flashlight_enabled
		print("[HIDE] Player came out of hiding")
		return

	# Try to hide in wardrobe
	var hide_areas = get_tree().get_nodes_in_group("wardrobe_hide")
	if hide_areas.size() > 0:
		var hide_area = hide_areas[0]
		var dist = global_position.distance_to(hide_area.global_position)
		if dist < 2.0:
			is_hiding = true
			unhide_pos = global_position
			# Animate camera forward into darkness
			if camera:
				var tween_cam = create_tween()
				tween_cam.tween_property(camera, "position", Vector3(0, -0.05, -0.3), 0.2).set_ease(Tween.EASE_OUT)
			# Move inside wardrobe
			global_position = hide_area.global_position + Vector3(0, 0, 0.7)
			# Close wardrobe doors
			var doors = get_tree().get_nodes_in_group("wardrobe_door")
			for door in doors:
				var tween_door = create_tween()
				tween_door.tween_property(door, "rotation:y", 0.5, 0.25).set_ease(Tween.EASE_OUT)
			# Play door sound
			var wardrobe = hide_area.get_parent()
			var door_sound_node = wardrobe.get_node("DoorSound") if wardrobe.has_node("DoorSound") else null
			if door_sound_node:
				door_sound_node.play()
			# Turn off flashlight
			if flashlight_light:
				flashlight_light.visible = false
			print("[HIDE] Player hid in wardrobe!")

func _on_interact():
	if in_terminal_mode:
		return
	if near_terminal:
		_open_terminal()
		return
	if has_key and near_exit_door:
		_win_game()
		return
	if near_color_puzzle:
		_interact_color_puzzle()
		return
	if is_hiding:
		_toggle_hide()
	elif near_wardrobe:
		_toggle_hide()
	else:
		_try_search_furniture()

func _interact_color_puzzle():
	var puzzles = get_tree().get_nodes_in_group("color_puzzle")
	for p in puzzles:
		if not is_instance_valid(p) or not p.has_method("cycle_color"):
			continue
		# Find which glass is closest to the player's view direction
		var closest = -1
		var closest_dot = -1.0
		var cam_fwd = -camera.global_transform.basis.z
		for i in range(3):
			var glass_pos = p.get_node("Glass" + str(i + 1)).global_position
			var dir_to_glass = (glass_pos - camera.global_position).normalized()
			var dot = cam_fwd.dot(dir_to_glass)
			if dot > closest_dot:
				closest_dot = dot
				closest = i
		if closest >= 0:
			p.cycle_color(closest)
		return

func _open_terminal():
	var terminals = get_tree().get_nodes_in_group("terminal")
	for t in terminals:
		if is_instance_valid(t) and t.has_method(&"open_terminal"):
			t.open_terminal(self)
			return

func set_terminal_mode(enabled: bool):
	in_terminal_mode = enabled
	if enabled:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func set_has_key(value: bool):
	has_key = value

func _check_terminal_proximity():
	var terminals = get_tree().get_nodes_in_group("terminal")
	near_terminal = false
	for t in terminals:
		if is_instance_valid(t):
			var dist = global_position.distance_to(t.global_position)
			if dist < 2.0:
				near_terminal = true
				return

func _check_door_proximity():
	var door_areas = get_tree().get_nodes_in_group("exit_door")
	near_exit_door = false
	for area in door_areas:
		if is_instance_valid(area):
			var dist = global_position.distance_to(area.global_position)
			if dist < 2.0:
				near_exit_door = true
				return

func _check_color_puzzle_proximity():
	var puzzles = get_tree().get_nodes_in_group("color_puzzle")
	near_color_puzzle = false
	for p in puzzles:
		if is_instance_valid(p):
			var dist = global_position.distance_to(p.global_position)
			if dist < 2.5:
				near_color_puzzle = true
				return

func _update_hud():
	if touch_controls and is_instance_valid(touch_controls):
		if touch_controls.has_method("set_battery"):
			touch_controls.set_battery(battery_level / battery_max)
		if touch_controls.has_method("set_time"):
			var total_minutes = START_HOUR * 60 + game_time / 60.0
			var hours = int(total_minutes / 60) % 24
			var minutes = int(total_minutes) % 60
			touch_controls.set_time(hours, minutes)

func _try_search_furniture():
	var player_pos = global_position
	var searched_any = false
	var furniture_nodes = get_tree().get_nodes_in_group("searchable")
	for furn in furniture_nodes:
		if not is_instance_valid(furn):
			continue
		var furn_key = str(furn.get_instance_id())
		# Check cooldown
		if search_cooldowns.has(furn_key) and search_cooldowns[furn_key] > 0:
			continue
		var dist = player_pos.distance_to(furn.global_position)
		if dist < 2.5:
			searched_any = true
			search_cooldowns[furn_key] = SEARCH_COOLDOWN_TIME
			# Random chance to find battery
			if randf() < SEARCH_BATTERY_CHANCE:
				var found = SEARCH_BATTERY_AMOUNT
				battery_level = min(battery_max, battery_level + found)
				print("[SEARCH] Found battery! +%.0f%%" % found)
			else:
				print("[SEARCH] Nothing here...")
			break

	if not searched_any:
		print("[SEARCH] Nothing to search nearby")

func reward_battery(amount: float):
	battery_level = min(battery_max, battery_level + amount)
	print("[REWARD] +%.0f%% battery for surviving!" % amount)

func _physics_process(delta):
	if is_hiding or in_terminal_mode:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y -= gravity * gravity_scale * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	if OS.has_feature("android"):
		input_dir = input_dir + move_input
		input_dir = input_dir.limit_length(1.0)

	# Use head's horizontal rotation only (ignore pitch) for movement
	var forward_dir = -head.global_transform.basis.z
	var right_dir = head.global_transform.basis.x
	var raw_move = right_dir * input_dir.x + forward_dir * (-input_dir.y)
	var direction = Vector3(raw_move.x, 0, raw_move.z).normalized()

	if direction:
		var target_velocity = direction * current_speed
		var accel = acceleration if is_on_floor() else air_acceleration
		velocity.x = lerp(velocity.x, target_velocity.x, accel * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, accel * delta)
	else:
		var friction = deceleration if is_on_floor() else air_acceleration
		velocity.x = lerp(velocity.x, 0.0, friction * delta)
		velocity.z = lerp(velocity.z, 0.0, friction * delta)

	move_and_slide()

func take_damage(amount: float):
	pass

func die():
	get_tree().reload_current_scene()

func set_move_input(input: Vector2):
	move_input = input

func set_look_delta(delta: Vector2):
	if not camera or not head:
		return
	if delta.length() > 0:
		head.rotate_y(-delta.x * touch_sensitivity)
		camera.rotate_x(-delta.y * touch_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func toggle_flashlight():
	if not flashlight_light:
		return
	if is_hiding:
		return
	if battery_level <= 0 and not flashlight_enabled:
		return
	flashlight_enabled = !flashlight_enabled
	flashlight_light.visible = flashlight_enabled

func _on_touch_flashlight():
	toggle_flashlight()

func _on_touch_jump():
	if not in_terminal_mode and is_on_floor():
		velocity.y = jump_velocity

func _on_touch_crouch():
	if not in_terminal_mode and not is_hiding:
		is_crouching = not is_crouching
		# Snap head height immediately
		var target_y = head_normal_pos.y - (0.4 if is_crouching else 0.0)
		head.position.y = target_y
		head_rest_pos.y = target_y

func _win_game():
	get_tree().change_scene_to_file("res://scenes/ui/win_screen.tscn")

func is_hiding_check() -> bool:
	return is_hiding
