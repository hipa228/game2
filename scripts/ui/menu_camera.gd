extends Camera3D

var start_pos: Vector3
var time: float = 0.0

func _ready():
	start_pos = position

func _process(delta):
	time += delta * 0.3
	# Very subtle sway
	position.x = start_pos.x + sin(time * 0.4) * 0.15
	position.y = start_pos.y + sin(time * 0.3 + 1.0) * 0.08
	# Occasional slight rotation
	rotation.z = sin(time * 0.25) * 0.005
