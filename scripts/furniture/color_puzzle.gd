extends StaticBody3D

enum GlassColor { RED, GREEN, BLUE, YELLOW }
const COLOR_NAMES := {GlassColor.RED: "Красный", GlassColor.GREEN: "Зелёный", GlassColor.BLUE: "Синий", GlassColor.YELLOW: "Жёлтый"}
const COLOR_VALUES := {GlassColor.RED: Color(1, 0.15, 0.1), GlassColor.GREEN: Color(0.1, 1, 0.3), GlassColor.BLUE: Color(0.15, 0.3, 1), GlassColor.YELLOW: Color(1, 0.9, 0.1)}

var target_sequence: Array = []
var current_sequence: Array = [GlassColor.RED, GlassColor.RED, GlassColor.RED]
var is_solved: bool = false

@onready var glass_nodes: Array = [$Glass1, $Glass2, $Glass3]
@onready var status_label: Label3D = $StatusLabel
@onready var hint_label: Label3D = $HintLabel
@onready var interact_area: Area3D = $InteractArea

signal puzzle_solved()

func _ready():
	_generate_target()
	_update_visuals()
	status_label.text = ""
	hint_label.text = ""
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _generate_target():
	var rng = RandomNumberGenerator.new()
	target_sequence.clear()
	for i in range(3):
		target_sequence.append(rng.randi() % 4)
	# Start with all glasses set to RED
	current_sequence = [GlassColor.RED, GlassColor.RED, GlassColor.RED]
	print("[COLOR PUZZLE] Target: ", target_sequence)

func _get_liquid_mat(glass_idx: int) -> Material:
	var liquid = glass_nodes[glass_idx].get_node("Liquid")
	if liquid:
		var mat = liquid.material_override
		if not mat:
			mat = StandardMaterial3D.new()
			liquid.material_override = mat
		return mat
	return null

func _get_liquid_top_mat(glass_idx: int) -> Material:
	var top = glass_nodes[glass_idx].get_node("LiquidTop")
	if top:
		var mat = top.material_override
		if not mat:
			mat = StandardMaterial3D.new()
			top.material_override = mat
		return mat
	return null

func _update_visuals():
	for i in range(3):
		var color_idx = current_sequence[i]
		var color_val = COLOR_VALUES[color_idx]
		var mat = _get_liquid_mat(i)
		if mat:
			mat.albedo_color = color_val
			if mat is StandardMaterial3D:
				mat.emission_enabled = true
				mat.emission = color_val * 0.6
				mat.emission_energy = 1.5
		var top_mat = _get_liquid_top_mat(i)
		if top_mat:
			top_mat.albedo_color = color_val * 0.9
			top_mat.emission_enabled = true
			top_mat.emission = color_val * 0.5

		var label: Label3D = glass_nodes[i].get_node("ColorLabel")
		if label:
			var name = COLOR_NAMES[color_idx]
			label.text = name
			label.modulate = color_val

func cycle_color(glass_idx: int):
	if is_solved:
		return
	current_sequence[glass_idx] = (current_sequence[glass_idx] + 1) % 4
	_update_visuals()
	_check_solution()

func _check_solution():
	for i in range(3):
		if current_sequence[i] != target_sequence[i]:
			status_label.text = "❌"
			status_label.modulate = Color(1, 0.3, 0.2)
			return

	is_solved = true
	status_label.text = "✓ РЕШЕНО!"
	status_label.modulate = Color(0.2, 1, 0.3)
	hint_label.text = ""

	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method(&"set_has_key"):
		player.set_has_key(true)
		print("[COLOR PUZZLE] Solved! Player got the key!")

	puzzle_solved.emit()

func _on_body_entered(body):
	if body.is_in_group("player"):
		if not is_solved:
			status_label.text = "Наведись на стакан и нажми E"
			status_label.modulate = Color(1, 1, 1)

func _on_body_exited(body):
	if body.is_in_group("player"):
		status_label.text = ""
