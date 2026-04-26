extends StaticBody3D

enum GlassColor { RED, GREEN, BLUE, YELLOW }
const COLOR_NAMES := {GlassColor.RED: "Красный", GlassColor.GREEN: "Зелёный", GlassColor.BLUE: "Синий", GlassColor.YELLOW: "Жёлтый"}
const COLOR_VALUES := {GlassColor.RED: Color(1, 0.15, 0.1), GlassColor.GREEN: Color(0.1, 1, 0.3), GlassColor.BLUE: Color(0.15, 0.3, 1), GlassColor.YELLOW: Color(1, 0.9, 0.1)}

var target_sequence: Array = []
var current_sequence: Array = [GlassColor.RED, GlassColor.RED, GlassColor.RED]
var is_solved: bool = false
var target_indicators: Array = []
var glass_flash_tweens: Array = [null, null, null]

# Key hunt
var key_pickup_node: Area3D = null
var tv_screen: Node3D = null
var hunt_label: Label3D = null
var timer_label: Label3D = null
var hunt_timer: float = 0.0
var hunt_active: bool = false
var key_collected: bool = false

const KEY_SPAWN_POSITIONS = [
	Vector3(-2, 1.2, 3),
	Vector3(3, 1.2, -4),
	Vector3(-5, 1.2, -2),
	Vector3(6, 1.2, 2),
	Vector3(1, 1.2, 5),
	Vector3(-6, 1.2, 4),
	Vector3(4, 1.2, -5),
	Vector3(-3, 1.2, -5),
	Vector3(-7, 1.2, -1),
	Vector3(7, 1.2, -3),
]

@onready var glass_nodes: Array = [$Glass1, $Glass2, $Glass3]
@onready var status_label: Label3D = $StatusLabel
@onready var hint_label: Label3D = $HintLabel
@onready var interact_area: Area3D = $InteractArea

signal puzzle_solved()

func _ready():
	_generate_target()
	_update_visuals()
	_setup_tv()
	_create_key_pickup()
	status_label.text = ""
	hint_label.text = ""
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _process(delta):
	if hunt_active and not key_collected:
		hunt_timer -= delta
		if hunt_timer <= 0:
			hunt_timer = 0
			_timer_expired()
		_update_timer_display()

# === GENERATION ===

func _generate_target():
	var rng = RandomNumberGenerator.new()
	target_sequence.clear()
	current_sequence.clear()
	for i in range(3):
		target_sequence.append(rng.randi() % 4)
		current_sequence.append(rng.randi() % 4)
	print("[COLOR PUZZLE] Target: ", target_sequence)

# === TV SETUP ===

func _setup_tv():
	tv_screen = get_tree().current_scene.find_child("TVScreenMesh", true, false)
	if not tv_screen or not is_instance_valid(tv_screen):
		print("[COLOR PUZZLE] TV not found")
		return

	# Target label
	var label = Label3D.new()
	label.name = "PuzzleTargetLabel"
	label.text = "ЦЕЛЬ:"
	label.font_size = 6
	label.outline_enabled = true
	label.outline_modulate = Color(0, 0, 0, 0.8)
	label.modulate = Color(0.5, 0.5, 0.5, 0.8)
	label.position = Vector3(-0.015, 0.55, 0)
	tv_screen.add_child(label)

	# Target color indicators
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
		mesh.position = Vector3(-0.015, 0.0, -0.6 + i * 0.6)
		tv_screen.add_child(mesh)
		target_indicators.append(mesh)

	# Hunt timer label (hidden initially)
	timer_label = Label3D.new()
	timer_label.name = "HuntTimerLabel"
	timer_label.font_size = 8
	timer_label.outline_enabled = true
	timer_label.outline_modulate = Color(0, 0, 0, 1)
	timer_label.modulate = Color(1, 0.3, 0.1, 1)
	timer_label.position = Vector3(-0.015, -0.45, 0)
	timer_label.visible = false
	tv_screen.add_child(timer_label)

	# Hunt countdown label (created on demand)
	hunt_label = Label3D.new()
	hunt_label.name = "HuntCountdownLabel"
	hunt_label.outline_enabled = true
	hunt_label.outline_modulate = Color(0, 0, 0, 1)
	hunt_label.modulate = Color(1, 0.2, 0.05, 1)
	hunt_label.position = Vector3(-0.015, 0.2, 0)
	hunt_label.visible = false
	tv_screen.add_child(hunt_label)

func _set_tv_label_text(text: String, font_size: int = 14):
	if not is_instance_valid(hunt_label):
		return
	hunt_label.text = text
	hunt_label.font_size = font_size
	hunt_label.visible = true

# === KEY PICKUP ===

func _create_key_pickup():
	key_pickup_node = Area3D.new()
	key_pickup_node.name = "KeyPickup"

	var collision = CollisionShape3D.new()
	collision.shape = SphereShape3D.new()
	collision.shape.radius = 0.4
	key_pickup_node.add_child(collision)

	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.2, 0.2, 0.15)
	mesh.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.85, 0.1)
	mat.emission = Color(1, 0.85, 0.1) * 0.5
	mat.emission_energy_multiplier = 3.0
	mesh.material_override = mat
	key_pickup_node.add_child(mesh)

	var light = OmniLight3D.new()
	light.light_energy = 1.0
	light.light_color = Color(1, 0.85, 0.1)
	light.omni_range = 3.0
	key_pickup_node.add_child(light)

	key_pickup_node.visible = false
	key_pickup_node.process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().current_scene.add_child(key_pickup_node)
	key_pickup_node.body_entered.connect(_on_key_pickup)

func _spawn_key():
	var pos = KEY_SPAWN_POSITIONS[randi() % KEY_SPAWN_POSITIONS.size()]
	key_pickup_node.global_position = pos
	key_pickup_node.visible = true
	key_pickup_node.process_mode = Node.PROCESS_MODE_INHERIT

func _on_key_pickup(body: Node):
	if not body.is_in_group("player") or key_collected:
		return

	key_collected = true
	hunt_active = false
	key_pickup_node.visible = false
	key_pickup_node.process_mode = Node.PROCESS_MODE_DISABLED

	if body.has_method("set_has_key"):
		body.set_has_key(true)

	_set_tv_label_text("КЛЮЧ\nНАЙДЕН!", 10)
	if timer_label:
		timer_label.visible = false
	print("[KEY HUNT] Key collected! Go to exit door!")

# === KEY HUNT ===

func _start_key_hunt():
	print("[KEY HUNT] Starting!")
	_set_tv_label_text("3", 16)
	await get_tree().create_timer(0.8).timeout
	_set_tv_label_text("2", 16)
	await get_tree().create_timer(0.8).timeout
	_set_tv_label_text("1", 16)
	await get_tree().create_timer(0.8).timeout

	_spawn_key()
	_set_tv_label_text("ИЩИ!", 12)
	await get_tree().create_timer(1.0).timeout

	hunt_label.visible = false
	hunt_active = true
	hunt_timer = 60.0
	if is_instance_valid(timer_label):
		timer_label.visible = true

func _timer_expired():
	hunt_active = false
	_set_tv_label_text("ВРЕМЯ\nВЫШЛО!", 12)
	if is_instance_valid(timer_label):
		timer_label.visible = false

	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("die"):
		await get_tree().create_timer(2.0).timeout
		player.die()

func _update_timer_display():
	if not is_instance_valid(timer_label):
		return
	var remaining = int(ceil(hunt_timer))
	timer_label.text = "%d:%02d" % [remaining / 60, remaining % 60]
	if hunt_timer < 10.0:
		timer_label.modulate = Color(1, 0.1, 0.1, 0.7 + sin(Time.get_ticks_msec() * 0.01) * 0.3)

# === VISUALS ===

func _update_target_display():
	if target_indicators.is_empty():
		return
	var done = Color(0.2, 0.8, 0.2)
	for i in target_indicators.size():
		var m = target_indicators[i]
		if not is_instance_valid(m):
			continue
		var mat = m.material_override
		if not mat:
			continue
		if is_solved:
			mat.albedo_color = done
			mat.emission = done * 0.5
		else:
			var c = COLOR_VALUES[target_sequence[i]]
			mat.albedo_color = c
			mat.emission = c * 0.6

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
		var c_idx = current_sequence[i]
		var c_val = COLOR_VALUES[c_idx]
		var mat = _get_liquid_mat(i)
		if mat:
			mat.albedo_color = c_val
			if mat is StandardMaterial3D:
				mat.emission = c_val * 0.6
				mat.emission_energy_multiplier = 1.5
		var t_mat = _get_liquid_top_mat(i)
		if t_mat:
			t_mat.albedo_color = c_val * 0.9
			t_mat.emission = c_val * 0.5
		var lbl: Label3D = glass_nodes[i].get_node("ColorLabel")
		if lbl:
			lbl.text = COLOR_NAMES[c_idx]
			lbl.modulate = c_val

# === INTERACTION ===

func cycle_color(glass_idx: int):
	if is_solved:
		return
	current_sequence[glass_idx] = (current_sequence[glass_idx] + 1) % 4
	_update_visuals()
	# Flash green if this glass matches target
	if current_sequence[glass_idx] == target_sequence[glass_idx]:
		_flash_glass_green(glass_idx)
	_check_solution()

func _flash_glass_green(glass_idx: int):
	var mat = _get_liquid_mat(glass_idx)
	var t_mat = _get_liquid_top_mat(glass_idx)
	if not mat or not t_mat:
		return
	# Kill previous tween for this glass
	if glass_flash_tweens[glass_idx] and glass_flash_tweens[glass_idx].is_valid():
		glass_flash_tweens[glass_idx].kill()
	# Flash green: set emission to green, tween back to normal
	var green = Color(0, 1.5, 0)
	mat.emission = green
	t_mat.emission = green
	mat.emission_energy_multiplier = 3.0
	t_mat.emission_energy_multiplier = 3.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(mat, "emission", Color(0, 0, 0), 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "emission_energy_multiplier", 1.5, 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(t_mat, "emission", Color(0, 0, 0), 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(t_mat, "emission_energy_multiplier", 1.5, 0.4).set_ease(Tween.EASE_OUT)
	glass_flash_tweens[glass_idx] = tween

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
	puzzle_solved.emit()

	_start_key_hunt()

func _on_body_entered(body):
	if body.is_in_group("player"):
		if not is_solved:
			status_label.text = "Наведись на стакан и нажми E"
			status_label.modulate = Color(1, 1, 1)

func _on_body_exited(body):
	if body.is_in_group("player"):
		status_label.text = ""
