extends Node2D

const HINT_AFTER_ATTEMPTS := 3

var questions := [
	{"question": "What animal says \"meow\"?", "answer": "cat", "hint": "It is a small pet with whiskers."},
	{"question": "What color is the sun usually drawn?", "answer": "yellow", "hint": "It is the color of a lemon."},
	{"question": "How many legs does a dog have?", "answer": "four", "accepted": ["4"], "hint": "Count the paws on one dog."},
	{"question": "What do bees make?", "answer": "honey", "hint": "It is sweet and sticky."},
	{"question": "What season comes after winter?", "answer": "spring", "hint": "Flowers begin to grow in this season."}
]

var question_index := 0
var attempts := 0
var score := 0
var question_label: Label
var progress_label: Label
var score_label: Label
var feedback_label: Label
var hint_label: Label
var answer_input: LineEdit
var guess_button: Button
var next_button: Button


func _ready() -> void:
	_build_interface()
	_show_question()


func _build_interface() -> void:
	var canvas_layer := CanvasLayer.new()
	add_child(canvas_layer)

	var background := ColorRect.new()
	background.color = Color("#fff1c9")
	canvas_layer.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var top_accent := ColorRect.new()
	top_accent.color = Color("#ff7b9c")
	background.add_child(top_accent)
	top_accent.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_accent.offset_top = 0
	top_accent.offset_bottom = 14

	var bottom_accent := ColorRect.new()
	bottom_accent.color = Color("#67c7c1")
	background.add_child(bottom_accent)
	bottom_accent.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_accent.offset_top = -14
	bottom_accent.offset_bottom = 0

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(720, 0)
	column.add_theme_constant_override("separation", 16)
	center.add_child(column)

	var title := Label.new()
	title.text = "Guessing Garden"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("#e94f78"))
	column.add_child(title)

	var welcome := Label.new()
	welcome.text = "Read the question, type your answer, and have fun!"
	welcome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	welcome.add_theme_font_size_override("font_size", 20)
	welcome.add_theme_color_override("font_color", Color("#7956a8"))
	column.add_child(welcome)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(720, 330)
	card.add_theme_stylebox_override("panel", _make_panel_style("#fffafa", 24))
	column.add_child(card)

	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 32)
	card_margin.add_theme_constant_override("margin_top", 28)
	card_margin.add_theme_constant_override("margin_right", 32)
	card_margin.add_theme_constant_override("margin_bottom", 28)
	card.add_child(card_margin)
	
	var card_column := VBoxContainer.new()
	card_column.add_theme_constant_override("separation", 16)
	card_margin.add_child(card_column)

	progress_label = Label.new()
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 18)
	progress_label.add_theme_color_override("font_color", Color("#ef8a3c"))
	card_column.add_child(progress_label)

	question_label = Label.new()
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.add_theme_font_size_override("font_size", 29)
	question_label.add_theme_color_override("font_color", Color("#40558e"))
	card_column.add_child(question_label)
	
	answer_input = LineEdit.new()
	answer_input.placeholder_text = "Type your answer here..."
	answer_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	answer_input.custom_minimum_size = Vector2(0, 54)
	answer_input.add_theme_font_size_override("font_size", 24)
	answer_input.add_theme_stylebox_override("normal", _make_panel_style("#243484", 14))
	answer_input.text_submitted.connect(_on_answer_submitted)
	card_column.add_child(answer_input)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	card_column.add_child(buttons)

	guess_button = Button.new()
	guess_button.text = "Check answer"
	guess_button.custom_minimum_size = Vector2(180, 52)
	guess_button.add_theme_font_size_override("font_size", 20)
	guess_button.add_theme_color_override("font_color", Color.WHITE)
	guess_button.add_theme_stylebox_override("normal", _make_panel_style("#36b58a", 12))
	guess_button.add_theme_stylebox_override("hover", _make_panel_style("#269b74", 12))
	guess_button.pressed.connect(_check_answer)
	buttons.add_child(guess_button)

	next_button = Button.new()
	next_button.text = "Next question"
	next_button.custom_minimum_size = Vector2(180, 52)
	next_button.add_theme_font_size_override("font_size", 20)
	next_button.add_theme_color_override("font_color", Color.WHITE)
	next_button.add_theme_stylebox_override("normal", _make_panel_style("#f39b45", 12))
	next_button.add_theme_stylebox_override("hover", _make_panel_style("#e27d2c", 12))
	next_button.pressed.connect(_next_question)
	next_button.visible = false
	buttons.add_child(next_button)

	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_font_size_override("font_size", 19)
	hint_label.add_theme_color_override("font_color", Color("#d66b32"))
	card_column.add_child(hint_label)

	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.add_theme_font_size_override("font_size", 20)
	card_column.add_child(feedback_label)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 24)
	column.add_child(footer)

	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 20)
	score_label.add_theme_color_override("font_color", Color("#40558e"))
	footer.add_child(score_label)

	var reset_button := Button.new()
	reset_button.text = "  Play again  "
	reset_button.add_theme_font_size_override("font_size", 18)
	reset_button.pressed.connect(_reset_game)
	footer.add_child(reset_button)


func _make_panel_style(color: String, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

	
func _show_question() -> void:
	if question_index >= questions.size():
		_show_finished()
		return
	var current: Dictionary = questions[question_index]
	progress_label.text = "Question %d of %d" % [question_index + 1, questions.size()]
	question_label.text = current["question"]
	score_label.text = "Score: %d" % score
	answer_input.text = ""
	answer_input.editable = true
	guess_button.disabled = false
	guess_button.visible = true
	next_button.visible = false
	hint_label.text = ""
	feedback_label.text = ""
	feedback_label.add_theme_color_override("font_color", Color("#416b85"))
	answer_input.grab_focus()


func _check_answer() -> void:
	var guess := answer_input.text.strip_edges().to_lower()
	if guess.is_empty():
		feedback_label.text = "Type an answer first!"
		feedback_label.add_theme_color_override("font_color", Color("#b06b2d"))
		return

	var current: Dictionary = questions[question_index]
	var accepted: Array = current.get("accepted", [current["answer"]])
	if guess in accepted:
		score += 1
		feedback_label.text = "Great job! That is correct!"
		feedback_label.add_theme_color_override("font_color", Color("#318354"))
		answer_input.editable = false
		guess_button.disabled = true
		next_button.visible = true
		score_label.text = "Score: %d" % score
		return

	attempts += 1
	feedback_label.text = "Not quite. Try again!"
	feedback_label.add_theme_color_override("font_color", Color("#b06b2d"))
	if attempts >= HINT_AFTER_ATTEMPTS:
		hint_label.text = "Hint: " + current["hint"]


func _on_answer_submitted(_text: String) -> void:
	_check_answer()


func _next_question() -> void:
	question_index += 1
	attempts = 0
	_show_question()


func _show_finished() -> void:
	progress_label.text = "You finished all the questions!"
	question_label.text = "Amazing work! You scored %d out of %d." % [score, questions.size()]
	answer_input.visible = false
	guess_button.visible = false
	next_button.visible = false
	hint_label.text = "Press Play again to try for an even higher score."
	feedback_label.text = "Keep learning and keep guessing!"
	score_label.text = "Final score: %d" % score


func _reset_game() -> void:
	question_index = 0
	attempts = 0
	score = 0
	answer_input.visible = true
	_show_question()
