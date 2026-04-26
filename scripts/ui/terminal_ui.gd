extends Control

var terminal: Node = null

@onready var red_btn = %RedButton
@onready var green_btn = %GreenButton
@onready var blue_btn = %BlueButton
@onready var yellow_btn = %YellowButton
@onready var input_display = %InputDisplay
@onready var status_label = %StatusLabel
@onready var close_btn = %CloseButton

var color_btns: Array = []

const INPUT_EMPTY := "○ ○ ○ ○"

func connect_terminal(terminal_node: Node):
	terminal = terminal_node
	if terminal.has_signal(&"puzzle_solved"):
		terminal.puzzle_solved.connect(_on_solved)
	if terminal.has_signal(&"input_accepted"):
		terminal.input_accepted.connect(_on_input_accepted)
	if terminal.has_signal(&"input_rejected"):
		terminal.input_rejected.connect(_on_input_rejected)
	if terminal.has_signal(&"sequence_started"):
		terminal.sequence_started.connect(_on_sequence_started)
	if terminal.has_signal(&"sequence_ended"):
		terminal.sequence_ended.connect(_on_sequence_ended)

func _ready():
	color_btns = [red_btn, green_btn, blue_btn, yellow_btn]
	close_btn.pressed.connect(_on_close)
	for i in color_btns.size():
		color_btns[i].pressed.connect(_on_color_pressed.bind(i))
	input_display.text = INPUT_EMPTY
	_disable_colors(true)

func _on_color_pressed(color_idx: int):
	if terminal and terminal.has_method(&"check_input"):
		terminal.check_input(color_idx)

func _on_sequence_started():
	status_label.text = "Смотри на телевизор..."
	_disable_colors(true)

func _on_sequence_ended():
	status_label.text = "Введи последовательность цветов"
	_disable_colors(false)

func _on_input_accepted(index: int):
	status_label.text = "Верно! (%d/4)" % index
	_disable_colors(true)
	var display := []
	for i in range(index):
		display.append("●")
	for i in range(4 - index):
		display.append("○")
	input_display.text = " ".join(display)

func _on_input_rejected():
	status_label.text = "Неверно! Жди следующей последовательности"
	_disable_colors(true)
	input_display.text = INPUT_EMPTY

func _on_solved():
	status_label.text = "Доступ получен! Ключ активирован!"
	_disable_colors(true)
	red_btn.hide()
	green_btn.hide()
	blue_btn.hide()
	yellow_btn.hide()
	close_btn.text = "Выйти"

func _on_close():
	if terminal and terminal.has_method(&"close_terminal"):
		terminal.close_terminal()

func _disable_colors(disabled: bool):
	for btn in color_btns:
		btn.disabled = disabled
