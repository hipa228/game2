extends StaticBody3D

enum ColorType { RED, GREEN, BLUE, YELLOW }

const COLOR_TV := {
	ColorType.RED: Color(1, 0, 0),
	ColorType.GREEN: Color(0, 1, 0),
	ColorType.BLUE: Color(0, 0, 1),
	ColorType.YELLOW: Color(1, 1, 0),
}

@export var tv_screen_path: NodePath = NodePath("../TV/TVScreenMesh")
@export var sequence_length: int = 4

var tv_screen: MeshInstance3D
var tv_material: Material
var original_emission: Color
var original_energy: float

# Phase 1: Color sequence
var color_sequence: Array = []
var sequence_generated: bool = false
var player_input: Array = []
var input_index: int = 0
var is_playing: bool = false
var is_solved_phase1: bool = false
var is_open: bool = false
var player_ref: Node = null

# Phase 2: Knock count
var is_phase2: bool = false
var knock_count_to_guess: int = 0
var phase2_number_input: int = 0
var phase2_solved: bool = false
var knocks_played: bool = false

# Auto-play: sequence shows on TV every ~15s
var auto_timer: float = 5.0
@export var auto_interval_min: float = 12.0
@export var auto_interval_max: float = 25.0

var terminal_ui_scene: PackedScene
var terminal_ui_instance: Node = null

signal puzzle_solved()
signal sequence_started()
signal sequence_ended()
signal input_accepted(index: int)
signal input_rejected()
signal phase2_started()
signal knocks_started()
signal knocks_finished()
signal phase2_solved_signal()

func _ready():
	tv_screen = get_node(tv_screen_path)
	tv_material = tv_screen.material_override
	original_emission = tv_material.emission
	original_energy = tv_material.emission_energy
	terminal_ui_scene = preload("res://scenes/ui/terminal_ui.tscn")

func _process(delta):
	if is_solved_phase1:
		return
	auto_timer -= delta
	if auto_timer <= 0 and not is_playing:
		_auto_play()

func _auto_play():
	generate_sequence()
	is_playing = true
	_show_sequence_step(0)
	auto_timer = randf_range(auto_interval_min, auto_interval_max)

func generate_sequence():
	color_sequence.clear()
	for i in range(sequence_length):
		color_sequence.append(randi() % 4)
	sequence_generated = true

func play_sequence():
	if is_playing:
		return
	if not sequence_generated:
		generate_sequence()
	is_playing = true
	sequence_started.emit()
	_show_sequence_step(0)

func _show_sequence_step(index: int):
	if not is_inside_tree():
		is_playing = false
		return
	if index >= color_sequence.size():
		is_playing = false
		player_input.clear()
		input_index = 0
		sequence_ended.emit()
		return

	var color_idx = color_sequence[index] as int
	var color = COLOR_TV[color_idx]

	tv_material.emission = color
	tv_material.emission_energy = 10.0

	await get_tree().create_timer(0.8).timeout

	if not is_inside_tree():
		is_playing = false
		return

	tv_material.emission = Color(0, 0, 0)
	tv_material.emission_energy = 0.0

	await get_tree().create_timer(0.35).timeout

	_show_sequence_step(index + 1)

func check_input(color_idx: int) -> bool:
	if is_playing or is_solved_phase1 or not is_open:
		return false
	if input_index >= color_sequence.size():
		return false

	if color_idx == color_sequence[input_index]:
		player_input.append(color_idx)
		input_index += 1
		input_accepted.emit(input_index)

		if input_index >= color_sequence.size():
			_solve_phase1()
		return true
	else:
		input_rejected.emit()
		_flash_tv(Color(1, 0, 0))
		player_input.clear()
		input_index = 0
		return false

func _solve_phase1():
	is_solved_phase1 = true
	puzzle_solved.emit()
	_flash_tv(Color(0, 1, 0))
	await get_tree().create_timer(1.5).timeout
	close_terminal()
	_start_phase2()

func _start_phase2():
	is_phase2 = true
	knock_count_to_guess = randi_range(3, 8)
	print("[PUZZLE] Phase 2: %d knocks" % knock_count_to_guess)
	phase2_started.emit()

	# Find horror_events and trigger puzzle knocks
	await get_tree().create_timer(2.0).timeout
	var horror_events = get_node_or_null("../HorrorEvents")
	if horror_events and horror_events.has_method("play_puzzle_knocks"):
		knocks_started.emit()
		# Flash TV to signal knocks are coming
		if is_instance_valid(tv_material):
			tv_material.emission = Color(0.4, 0.2, 0.0)
			tv_material.emission_energy = 5.0
			await get_tree().create_timer(0.5).timeout
			_restore_tv()
		horror_events.play_puzzle_knocks(knock_count_to_guess, _on_puzzle_knocks_done)
	else:
		# Fallback: no horror_events found, just mark done
		knocks_played = true
		knocks_finished.emit()

func _on_puzzle_knocks_done():
	knocks_played = true
	knocks_finished.emit()
	print("[PUZZLE] Puzzle knocks finished! Player can now input count at terminal.")

func check_number_input(number: int) -> bool:
	if not is_open or not is_phase2 or not knocks_played:
		return false
	if number == knock_count_to_guess:
		phase2_solved = true
		phase2_solved_signal.emit()
		_flash_tv(Color(0, 1, 0))
		if player_ref and is_instance_valid(player_ref) and player_ref.has_method(&"set_has_key"):
			player_ref.set_has_key(true)
		print("[PUZZLE] Phase 2 solved! Key activated!")
		return true
	else:
		_flash_tv(Color(1, 0, 0))
		print("[PUZZLE] Wrong guess: %d (correct was %d)" % [number, knock_count_to_guess])
		return false

func _flash_tv(color: Color):
	if not is_inside_tree():
		return
	tv_material.emission = color
	tv_material.emission_energy = 8.0
	await get_tree().create_timer(0.6).timeout
	if not is_inside_tree():
		return
	_restore_tv()

func _restore_tv():
	if is_instance_valid(tv_material):
		tv_material.emission = original_emission
		tv_material.emission_energy = original_energy

func open_terminal(player: Node):
	if phase2_solved:
		return
	is_open = true
	player_ref = player
	if player.has_method(&"set_terminal_mode"):
		player.set_terminal_mode(true)

	if terminal_ui_instance == null or not is_instance_valid(terminal_ui_instance):
		terminal_ui_instance = terminal_ui_scene.instantiate()
		get_tree().root.add_child(terminal_ui_instance)

	if terminal_ui_instance and is_instance_valid(terminal_ui_instance):
		if terminal_ui_instance.has_method(&"connect_terminal"):
			terminal_ui_instance.connect_terminal(self)

	# Phase 2: show number input screen
	if is_phase2:
		terminal_ui_instance.set_phase2_mode(knocks_played, knock_count_to_guess)
		return

	# Phase 1: show color sequence
	play_sequence()

func close_terminal():
	is_open = false
	is_playing = false
	if terminal_ui_instance and is_instance_valid(terminal_ui_instance):
		terminal_ui_instance.queue_free()
		terminal_ui_instance = null

	if player_ref and is_instance_valid(player_ref):
		if player_ref.has_method(&"set_terminal_mode"):
			player_ref.set_terminal_mode(false)
		player_ref = null

	if is_instance_valid(tv_material):
		_restore_tv()

func is_terminal_active() -> bool:
	return is_open

func get_knock_count() -> int:
	return knock_count_to_guess

func is_phase2_active() -> bool:
	return is_phase2

func are_knocks_done() -> bool:
	return knocks_played

func is_fully_solved() -> bool:
	return phase2_solved
