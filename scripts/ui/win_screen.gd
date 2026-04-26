extends Control

@onready var restart_button: Button = $RestartButton
@onready var quit_button: Button = $QuitButton

func _ready():
	restart_button.pressed.connect(_on_restart)
	quit_button.pressed.connect(_on_quit)

func _on_restart():
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_quit():
	get_tree().quit()
