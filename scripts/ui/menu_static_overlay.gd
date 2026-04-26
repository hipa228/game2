extends ColorRect

var timer := 0.0

func _process(delta):
	timer -= delta
	if timer <= 0:
		var v = randf()
		if v > 0.92:
			# Bright flash
			color = Color(1, 1, 1, randf_range(0.05, 0.15))
		elif v > 0.7:
			# Dark interference
			color = Color(0, 0, 0, randf_range(0.03, 0.1))
		elif v > 0.5:
			# Faint noise
			var c = randf_range(0.3, 0.7)
			color = Color(c, c, c, randf_range(0.01, 0.04))
		else:
			color = Color(0, 0, 0, 0)
		timer = randf_range(0.016, 0.08)
