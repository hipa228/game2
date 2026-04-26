extends Control

var terminal: Node = null

@onready var red_btn = %RedButton
@onready var green_btn = %GreenButton
@onready var blue_btn = %BlueButton
@onready var yellow_btn = %YellowButton
@onready var input_display = %InputDisplay
@onready var status_label = %StatusLabel
@onready var close_btn = %CloseButton

# Phase 2 number input
@onready var phase2_panel = $Panel/VBox/Phase2Panel
@onready var number_display = %NumberDisplay
@onready var num_plus_btn = %NumPlus
@onready var num_minus_btn = %NumMinus
@onready var num_submit_btn = %NumSubmit
@onready var color_hbox = $Panel/VBox/ColorHBox

var color_btns: Array = []

const INPUT_EMPTY := "○ ○ ○ ○"
var current_number: int = 0
const MIN_NUMBER: int = 1
const MAX_NUMBER: int = 10

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
	if terminal.has_signal(&"knocks_started"):
		terminal.knocks_started.connect(_on_knocks_started)
	if terminal.has_signal(&"knocks_finished"):
		terminal.knocks_finished.connect(_on_knocks_finished)
	if terminal.has_signal(&"phase2_solved_signal"):
		terminal.phase2_solved_signal.connect(_on_phase2_solved)

func _ready():
	color_btns = [red_btn, green_btn, blue_btn, yellow_btn]
	close_btn.pressed.connect(_on_close)
	for i in color_btns.size():
		color_btns[i].pressed.connect(_on_color_pressed.bind(i))
	num_plus_btn.pressed.connect(_on_num_plus)
	num_minus_btn.pressed.connect(_on_num_minus)
	num_submit_btn.pressed.connect(_on_num_submit)
	input_display.text = INPUT_EMPTY
	_disable_colors(true)
	phase2_panel.hide()
	current_number = MIN_NUMBER
	number_display.text = str(current_number)

func set_phase2_mode(knocks_done: bool, _knock_count: int):
	color_hbox.hide()
	input_display.hide()
	phase2_panel.show()
	if knocks_done:
		status_label.text = "Сколько раз постучали в окно?"
		num_submit_btn.disabled = false
	else:
		status_label.text = "Жди... стук скоро начнётся"
		num_submit_btn.disabled = true

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
	status_label.text = "Фаза 1 пройдена! Готовься..."
	_disable_colors(true)
	red_btn.hide()
	green_btn.hide()
	blue_btn.hide()
	yellow_btn.hide()

func _on_knocks_started():
	pass

func _on_knocks_finished():
	status_label.text = "Сколько раз постучали в окно?"
	num_submit_btn.disabled = false
	current_number = MIN_NUMBER
	number_display.text = str(current_number)

func _on_phase2_solved():
	status_label.text = "Доступ получен! Ключ активирован!"
	num_submit_btn.hide()
	num_plus_btn.hide()
	num_minus_btn.hide()
	number_display.text = "✓ %d" % current_number
	close_btn.text = "Выйти"

func _on_num_plus():
	current_number = mini(current_number + 1, MAX_NUMBER)
	number_display.text = str(current_number)

func _on_num_minus():
	current_number = maxi(current_number - 1, MIN_NUMBER)
	number_display.text = str(current_number)

func _on_num_submit():
	if terminal and terminal.has_method(&"check_number_input"):
		num_submit_btn.disabled = true
		var correct = terminal.check_number_input(current_number)
		if not correct:
			num_submit_btn.disabled = false
			status_label.text = "Неверно! Попробуй ещё раз"

func _on_close():
	if terminal and terminal.has_method(&"close_terminal"):
		terminal.close_terminal()

func _disable_colors(disabled: bool):
	for btn in color_btns:
		btn.disabled = disabled
