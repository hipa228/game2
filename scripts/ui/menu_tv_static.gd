extends StaticBody3D

@onready var screen_mesh: MeshInstance3D = $TVScreenMesh
@onready var glow: OmniLight3D = $TVGlow
var flicker_timer := 0.0
var glitch_timer := 0.0
var is_glitching := false

func _ready():
	screen_mesh.material_override = screen_mesh.material_override.duplicate()
	flicker_timer = randf_range(0.01, 0.15)

func _process(delta):
	flicker_timer -= delta
	if flicker_timer <= 0:
		var val = randf()
		if val < 0.15:
			# Bright white flash (rare, intense)
			screen_mesh.material_override.emission = Color(1, 1, 1, 1)
			screen_mesh.material_override.emission_energy = randf_range(8.0, 15.0)
			glow.light_energy = randf_range(3.0, 6.0)
			glow.light_color = Color(1, 0.95, 0.9, 1)
			flicker_timer = randf_range(0.02, 0.06)
		elif val < 0.35:
			# Colored interference
			var r = randf_range(0.3, 1.0)
			var g = randf_range(0.1, 0.6)
			var b = randf_range(0.2, 0.8)
			screen_mesh.material_override.emission = Color(r, g, b, 1)
			screen_mesh.material_override.emission_energy = randf_range(3.0, 8.0)
			glow.light_energy = randf_range(1.0, 3.0)
			glow.light_color = Color(r * 0.5, g * 0.5, b * 0.5, 1)
			flicker_timer = randf_range(0.03, 0.1)
		elif val < 0.75:
			# Gray static noise
			var g = randf_range(0.1, 0.9)
			var flicker = randf_range(0.8, 1.2)
			screen_mesh.material_override.emission = Color(g * flicker, g * flicker * 0.9, g * flicker * 0.7, 1)
			screen_mesh.material_override.emission_energy = randf_range(1.0, 6.0)
			glow.light_energy = randf_range(0.3, 2.0)
			glow.light_color = Color(0.1, 0.12, 0.3, 1)
			flicker_timer = randf_range(0.02, 0.12)
		else:
			# Dark / off
			screen_mesh.material_override.emission = Color(0.01, 0.01, 0.03, 1)
			screen_mesh.material_override.emission_energy = randf_range(0.05, 0.3)
			glow.light_energy = randf_range(0.02, 0.1)
			glow.light_color = Color(0.05, 0.08, 0.15, 1)
			flicker_timer = randf_range(0.05, 0.3)

	# Occasional screen glitch (horizontal bar)
	glitch_timer -= delta
	if glitch_timer <= 0:
		if is_glitching:
			is_glitching = false
			glitch_timer = randf_range(2.0, 6.0)
		else:
			is_glitching = true
			# Bright horizontal bar effect
			screen_mesh.material_override.emission = Color(0.9, 0.9, 1, 1)
			screen_mesh.material_override.emission_energy = randf_range(5.0, 10.0)
			glow.light_energy = randf_range(2.0, 4.0)
			glow.light_color = Color(0.8, 0.8, 1, 1)
			glitch_timer = randf_range(0.05, 0.15)
