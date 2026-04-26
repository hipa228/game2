extends Node

enum EventType { WINDOW_KNOCK, DOOR_CREAK }

@onready var tv_screen = $"../TV/TVScreenMesh"
@onready var tv_glow = $"../TV/TVGlow"
@onready var window_glass = $"../Window/WindowGlassMesh"
@onready var knock_sound = $"../Window/KnockSound"
@onready var door_node = $"../Door"
@onready var wardrobe_hide = $"../Wardrobe/WardrobeHide"
@onready var player = $"../Player"
@onready var camera = $"../Player/Head/Camera3D"
@onready var tv_pos = $"../TV".global_position

var event_active = false
var is_hidden = false
var next_event_time = 10.0
var event_timer = 0.0
var current_event = -1

# TV flicker
var tv_flicker_timer = 0.0
var tv_on = false

# Window knock sequence
var knock_count = 0
var knock_timer = 0.0
var knock_index = 0

# Jumpscare
var scared_this_event := false
var screen_overlay: ColorRect = null

func _ready():
	next_event_time = randf_range(8.0, 15.0)

func _process(delta):
	# Pause horror events while player is using terminal
	if player and player.in_terminal_mode:
		return
	if event_active:
		event_timer -= delta

		# Window knock sequence
		if current_event == EventType.WINDOW_KNOCK:
			knock_timer -= delta
			if knock_timer <= 0 and knock_index < knock_count:
				do_single_knock()
				knock_index += 1
				knock_timer = randf_range(0.4, 0.8)

		# Check hiding
		is_hidden = false
		for body in wardrobe_hide.get_overlapping_bodies():
			if body == player:
				is_hidden = true
				break
		if not is_hidden and player and player.has_method(&"is_hiding_check"):
			is_hidden = player.is_hiding_check()

		if event_timer <= 0:
			end_event()
	else:
		next_event_time -= delta
		if next_event_time <= 0:
			start_random_event()

func start_random_event():
	var events = [EventType.WINDOW_KNOCK, EventType.DOOR_CREAK]
	current_event = events[randi() % events.size()]
	scared_this_event = false
	match current_event:
		EventType.WINDOW_KNOCK:
			start_window_knock()
		EventType.DOOR_CREAK:
			start_door_creak()

func start_window_knock():
	event_active = true
	event_timer = 4.5
	knock_count = randi_range(3, 6)
	knock_index = 0
	knock_timer = 0.0
	print("[EVENT] Window knock! Hide!")
	do_single_knock()
	knock_index = 1
	knock_timer = randf_range(0.4, 0.8)

func do_single_knock():
	if window_glass:
		var mat = window_glass.material_override
		mat.albedo_color = Color(1, 1, 1, 0.9)
	if knock_sound:
		knock_sound.play()
	if camera:
		var tween = create_tween()
		tween.tween_property(camera, "position", Vector3(randf_range(-0.08, 0.08), randf_range(-0.08, 0.08), 0), 0.03)
		tween.tween_property(camera, "position", Vector3.ZERO, 0.06)

func start_door_creak():
	event_active = true
	event_timer = 5.5
	print("[EVENT] Door creak! Hide!")
	var tween = create_tween()
	tween.tween_property(door_node, "rotation:y", 1.2, 0.6)
	tween.tween_property(door_node, "rotation:y", 1.1, 0.25)
	tween.tween_property(door_node, "rotation:y", 1.3, 0.3)

func end_event():
	event_active = false

	# Keep TV in normal state
	var tv_mat = tv_screen.material_override
	tv_mat.emission = Color(0.08, 0.12, 0.25, 1)
	tv_mat.emission_energy = 1.5
	tv_glow.light_energy = 0.8
	tv_glow.light_color = Color(0.1, 0.15, 0.35, 1)

	# Reset window
	var win_mat = window_glass.material_override
	win_mat.albedo_color = Color(0.3, 0.4, 0.6, 0.35)

	# Reset door
	var door_tween = create_tween()
	door_tween.tween_property(door_node, "rotation:y", 0.0, 0.4)

	# Reset camera
	if camera:
		camera.position = Vector3.ZERO

	# If not hidden -> jumpscare
	if not scared_this_event:
		if not is_hidden:
			do_jumpscare()

		# Reward for surviving
	if not scared_this_event:
		if player and player.has_method("reward_battery"):
			player.reward_battery(15.0)
			print("[EVENT] +15% battery for surviving!")

	next_event_time = randf_range(5.0, 12.0)

func do_jumpscare():
	scared_this_event = true
	print("[SCARE] Jumpscare!")
	if camera:
		var tween = create_tween()
		# Camera shake
		tween.tween_property(camera, "position", Vector3(randf_range(-0.2, 0.2), randf_range(-0.15, 0.15), 0), 0.03)
		tween.tween_property(camera, "position", Vector3.ZERO, 0.5)
