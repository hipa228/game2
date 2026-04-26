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
var last_pressed_btn: Button = null

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
	_style_buttons()

func _style_buttons():
	var color_pairs = [
		[Color(1, 0.2, 0.15), red_btn],
		[Color(0.15, 1, 0.3), green_btn],
		[Color(0.2, 0.4, 1), blue_btn],
		[Color(1, 0.9, 0.1), yellow_btn],
	]
	for pair in color_pairs:
		var c = pair[0]
		var btn = pair[1]
		var normal = StyleBoxFlat.new()
		normal.bg_color = Color(c.r * 0.15, c.g * 0.15, c.b * 0.15, 0.3)
		normal.set_corner_radius_all(8)
		normal.border_width_all = 1
		normal.border_color = Color(c.r, c.g, c.b, 0.3)
		var hover = StyleBoxFlat.new()
		hover.bg_color = Color(c.r * 0.3, c.g * 0.3, c.b * 0.3, 0.5)
		hover.set_corner_radius_all(8)
		hover.border_width_all = 1
		hover.border_color = Color(c.r, c.g, c.b, 0.6)
		var pressed = StyleBoxFlat.new()
		pressed.bg_color = Color(c.r * 0.5, c.g * 0.5, c.b * 0.5, 0.7)
		pressed.set_corner_radius_all(8)
		pressed.border_width_all = 1
		pressed.border_color = Color(c.r, c.g, c.b, 0.9)
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", pressed)

	# Style for close button
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.1, 0.1, 0.12, 0.4)
	close_style.set_corner_radius_all(6)
	close_style.border_width_all = 1
	close_style.border_color = Color(0.4, 0.4, 0.4, 0.2)
	close_btn.add_theme_stylebox_override("normal", close_style)

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
	last_pressed_btn = color_btns[color_idx]
	# Instant green flash on press
	last_pressed_btn.modulate = Color(0, 2, 0, 1)
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
	# Flash last pressed button green
	if last_pressed_btn and is_instance_valid(last_pressed_btn):
		var tween = create_tween()
		tween.tween_property(last_pressed_btn, "modulate", Color(0, 2, 0, 1), 0.05)
		tween.tween_property(last_pressed_btn, "modulate", Color(1, 1, 1, 1), 0.4).set_ease(Tween.EASE_OUT)
		last_pressed_btn = null

func _on_input_rejected():
	status_label.text = "Неверно! Жди следующей последовательности"
	_disable_colors(true)
	input_display.text = INPUT_EMPTY
	# Flash last pressed button red
	if last_pressed_btn and is_instance_valid(last_pressed_btn):
		var tween = create_tween()
		tween.tween_property(last_pressed_btn, "modulate", Color(2, 0, 0, 1), 0.05)
		tween.tween_property(last_pressed_btn, "modulate", Color(1, 1, 1, 1), 0.4).set_ease(Tween.EASE_OUT)
		last_pressed_btn = null

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
