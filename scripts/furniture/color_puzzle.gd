extends StaticBody3D

enum GlassColor { RED, GREEN, BLUE, YELLOW }
const COLOR_NAMES := {GlassColor.RED: "Красный", GlassColor.GREEN: "Зелёный", GlassColor.BLUE: "Синий", GlassColor.YELLOW: "Жёлтый"}
const COLOR_VALUES := {GlassColor.RED: Color(1, 0.15, 0.1), GlassColor.GREEN: Color(0.1, 1, 0.3), GlassColor.BLUE: Color(0.15, 0.3, 1), GlassColor.YELLOW: Color(1, 0.9, 0.1)}

var target_sequence: Array = []
var current_sequence: Array = [GlassColor.RED, GlassColor.RED, GlassColor.RED]
var is_solved: bool = false
var target_indicators: Array = []

@onready var glass_nodes: Array = [$Glass1, $Glass2, $Glass3]
@onready var status_label: Label3D = $StatusLabel
@onready var hint_label: Label3D = $HintLabel
@onready var interact_area: Area3D = $InteractArea

signal puzzle_solved()

func _ready():
	_generate_target()
	_update_visuals()
	_setup_tv_target_display()
	status_label.text = ""
	hint_label.text = ""
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _generate_target():
	var rng = RandomNumberGenerator.new()
	target_sequence.clear()
	current_sequence.clear()
	for i in range(3):
		target_sequence.append(rng.randi() % 4)
		current_sequence.append(rng.randi() % 4)
	print("[COLOR PUZZLE] Target: ", target_sequence)
	print("[COLOR PUZZLE] Initial: ", current_sequence)

func _setup_tv_target_display():
	var tv_screen = get_tree().current_scene.find_child("TVScreenMesh", true, false)
	if not tv_screen or not is_instance_valid(tv_screen):
		print("[COLOR PUZZLE] TV not found, skipping target display")
		return

	# Label above the colors
	var label = Label3D.new()
	label.name = "PuzzleTargetLabel"
	label.text = "ЦЕЛЬ:"
	label.font_size = 6
	label.outline_enabled = true
	label.outline_modulate = Color(0, 0, 0, 0.8)
	label.modulate = Color(0.5, 0.5, 0.5, 0.8)
	label.position = Vector3(0.01, 0.55, 0)
	tv_screen.add_child(label)

	# 3 colored indicator squares on the TV screen
	for i in range(3):
		var mesh = MeshInstance3D.new()
		mesh.name = "TargetIndicator" + str(i)

		var box = BoxMesh.new()
		box.size = Vector3(0.02, 0.3, 0.35)
		mesh.mesh = box

		var color = COLOR_VALUES[target_sequence[i]]
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission = color * 0.6
		mat.emission_energy_multiplier = 1.0
		mesh.material_override = mat

		# Spread across the TV screen (TV screen Z range is roughly -0.9 to 0.9)
		var z_pos = -0.6 + i * 0.6
		mesh.position = Vector3(-0.015, 0.0, z_pos)
		tv_screen.add_child(mesh)
		target_indicators.append(mesh)

func _update_target_display():
	if target_indicators.is_empty():
		return

	var solved_color = Color(0.2, 0.8, 0.2)
	for i in range(target_indicators.size()):
		var mesh = target_indicators[i]
		if not is_instance_valid(mesh):
			continue
		var mat = mesh.material_override
		if not mat:
			continue
		if is_solved:
			mat.albedo_color = solved_color
			mat.emission = solved_color * 0.5
		else:
			var color = COLOR_VALUES[target_sequence[i]]
			mat.albedo_color = color
			mat.emission = color * 0.6

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
				mat.emission = color_val * 0.6
				mat.emission_energy_multiplier = 1.5
		var top_mat = _get_liquid_top_mat(i)
		if top_mat:
			top_mat.albedo_color = color_val * 0.9
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
	_update_target_display()

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
