extends Node

var mouse_sensitivity: float = 0.003

func _ready():
	load_settings()

func save_settings():
	var config = ConfigFile.new()
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.save("user://settings.cfg")

func load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		mouse_sensitivity = config.get_value("controls", "mouse_sensitivity", 0.003)
