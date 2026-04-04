extends Node

signal game_started
signal game_paused
signal game_resumed
signal game_over
signal score_changed(new_score: int)

var score : int = 0:
	set(value):
		score = value
		score_changed.emit(score)

var is_game_paused : bool = false
var player_health : float = 100.0
var player_max_health : float = 100.0
var current_level : String = ""
var player_instance : Node = null

func _ready():
	# Load saved data
	_load_game_data()
	# Connect to scene change
	get_tree().node_added.connect(_on_node_added)

func start_new_game():
	score = 0
	player_health = player_max_health
	is_game_paused = false
	game_started.emit()

func pause_game():
	if not is_game_paused:
		is_game_paused = true
		game_paused.emit()

func resume_game():
	if is_game_paused:
		is_game_paused = false
		game_resumed.emit()

func game_over():
	game_over.emit()
	_save_game_data()

func add_points(points: int):
	score += points

func take_damage(amount: float):
	player_health = max(0, player_health - amount)
	if player_health <= 0:
		game_over()

func heal(amount: float):
	player_health = min(player_max_health, player_health + amount)

func set_player_instance(player: Node):
	player_instance = player

func get_player_position() -> Vector3:
	if player_instance and is_instance_valid(player_instance):
		return player_instance.global_position
	return Vector3.ZERO

func _load_game_data():
	# Load saved score and settings
	var save_game = FileAccess.open("user://savegame.save", FileAccess.READ)
	if save_game:
		score = save_game.get_32()
		save_game.close()

func _save_game_data():
	# Save score
	var save_game = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	if save_game:
		save_game.store_32(score)
		save_game.close()

func _on_node_added(node: Node):
	# Check if player was added to scene
	if node.is_in_group("player"):
		set_player_instance(node)