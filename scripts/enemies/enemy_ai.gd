extends CharacterBody3D

enum State { PATROL, CHASE, RETURN }

@export var patrol_speed : float = 2.0
@export var chase_speed : float = 4.0
@export var patrol_points : Array[Vector3] = []
@export var detection_range : float = 10.0
@export var chase_range : float = 20.0
@export var lose_range : float = 25.0

var current_state : State = State.PATROL
var target_position : Vector3 = Vector3.ZERO
var current_patrol_index : int = 0
var player_ref : Node3D = null
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var detection_area : Area3D = $DetectionArea
@onready var navigation_agent : NavigationAgent3D = $NavigationAgent3D

func _ready():
	if patrol_points.is_empty():
		# Default patrol points around current position
		patrol_points = [
			global_position + Vector3(5, 0, 0),
			global_position + Vector3(0, 0, 5),
			global_position + Vector3(-5, 0, 0),
			global_position + Vector3(0, 0, -5)
		]

	target_position = patrol_points[0]
	navigation_agent.target_position = target_position

	# Connect detection area signals
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	match current_state:
		State.PATROL:
			_patrol_state(delta)
		State.CHASE:
			_chase_state(delta)
		State.RETURN:
			_return_state(delta)

	move_and_slide()

func _patrol_state(delta):
	# Move to current patrol point
	var direction = _get_navigation_direction()
	if direction:
		velocity.x = direction.x * patrol_speed
		velocity.z = direction.z * patrol_speed
		# Rotate towards movement direction
		if direction.length() > 0.1:
			look_at(global_position + direction, Vector3.UP)
	else:
		# Reached patrol point, go to next
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		target_position = patrol_points[current_patrol_index]
		navigation_agent.target_position = target_position

func _chase_state(delta):
	if not player_ref:
		current_state = State.RETURN
		return

	# Check if player is still in chase range
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	if distance_to_player > lose_range:
		player_ref = null
		current_state = State.RETURN
		return

	# Chase player
	navigation_agent.target_position = player_ref.global_position
	var direction = _get_navigation_direction()
	if direction:
		velocity.x = direction.x * chase_speed
		velocity.z = direction.z * chase_speed
		# Look at player
		look_at(player_ref.global_position, Vector3.UP)

func _return_state(delta):
	# Return to last patrol point
	navigation_agent.target_position = target_position
	var direction = _get_navigation_direction()
	if direction:
		velocity.x = direction.x * patrol_speed
		velocity.z = direction.z * patrol_speed

		# Check if returned to patrol point
		if global_position.distance_to(target_position) < 1.0:
			current_state = State.PATROL
	else:
		current_state = State.PATROL

func _get_navigation_direction() -> Vector3:
	var target_pos = navigation_agent.get_next_path_position()
	var direction = (target_pos - global_position).normalized()
	direction.y = 0
	return direction

func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		player_ref = body
		current_state = State.CHASE
		print("Enemy detected player!")

func _on_body_exited(body: Node3D):
	if body == player_ref:
		# Player left detection area but may still be in chase range
		pass

# Public method to take damage
func take_damage(amount: float):
	# Implement enemy health
	pass

func die():
	# Implement death effects
	queue_free()