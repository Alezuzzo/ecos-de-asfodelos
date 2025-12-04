extends Control

@onready var item_start    : HBoxContainer = $Root/VBox/ItemStart
@onready var item_options  : HBoxContainer = $Root/VBox/ItemOptions
@onready var item_quit     : HBoxContainer = $Root/VBox/ItemQuit

@onready var start_button  : Button = item_start.get_node("StartButton")
@onready var options_button: Button = item_options.get_node("OptionsButton")
@onready var quit_button   : Button = item_quit.get_node("QuitButton")

@onready var arrow_start   : Label  = item_start.get_node("ArrowStart")
@onready var arrow_options : Label  = item_options.get_node("ArrowOptions")
@onready var arrow_quit    : Label  = item_quit.get_node("ArrowQuit")

const DIFFICULTY_SCENE := preload("res://scenes/menu/DifficultySelect.tscn")
const OPTIONS_SCENE := preload("res://scenes/menu/OptionsMenu.tscn")

func _ready() -> void:
	for a in [arrow_start, arrow_options, arrow_quit]:
		if a == null: continue
		if a.text.strip_edges() == "": a.text = "▶"
		a.visible = false
		if a.custom_minimum_size == Vector2.ZERO:
			a.custom_minimum_size = Vector2(32, 32)
		a.pivot_offset = a.size / 2.0
		a.resized.connect(func(): a.pivot_offset = a.size / 2.0)

	for b in [start_button, options_button, quit_button]:
		if b == null: continue
		b.flat = true
		b.focus_mode = Control.FOCUS_ALL
		b.mouse_entered.connect(func(): b.grab_focus())

	_wire_arrow_static(start_button,  arrow_start)
	_wire_arrow_static(options_button, arrow_options)
	_wire_arrow_static(quit_button,   arrow_quit)

	start_button.pressed.connect(_on_start)
	options_button.pressed.connect(_on_options)
	quit_button.pressed.connect(_on_quit)

	start_button.grab_focus()

func _input(event: InputEvent) -> void:
	# Botão A do controle ativa o botão com foco
	if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_A and event.pressed:
		var viewport = get_viewport()
		if not viewport:
			return
		var focused = viewport.gui_get_focus_owner()
		if focused is Button:
			focused.emit_signal("pressed")
			viewport.set_input_as_handled()

func _wire_arrow_static(btn: Button, arrow: Label) -> void:
	if btn == null or arrow == null: return
	btn.focus_entered.connect(func():
		arrow.visible = true
		_tint(btn, Color(0.95, 0.85, 0.55))
	)
	btn.focus_exited.connect(func():
		arrow.visible = false
		_tint(btn, Color.WHITE)
	)

func _tint(node: CanvasItem, col: Color) -> void:
	var tw := create_tween()
	tw.tween_property(node, "modulate", col, 0.08)

func _on_start() -> void:
	var difficulty_menu = DIFFICULTY_SCENE.instantiate()
	add_child(difficulty_menu)
	# Quando o menu de dificuldade for fechado, recupera o foco
	difficulty_menu.tree_exiting.connect(func(): start_button.grab_focus())

func _on_options() -> void:
	var options_menu = OPTIONS_SCENE.instantiate()
	add_child(options_menu)
	# Quando o menu de opções for fechado, recupera o foco
	options_menu.tree_exiting.connect(func(): options_button.grab_focus())

func _on_quit() -> void:
	get_tree().quit()

func _flash(msg: String) -> void:
	var l := Label.new()
	l.text = msg
	l.modulate.a = 0.0
	add_child(l)
	l.global_position = Vector2(40, get_viewport_rect().size.y - 60)
	var t := create_tween()
	t.tween_property(l, "modulate:a", 1.0, 0.12)
	t.tween_interval(0.7)
	t.tween_property(l, "modulate:a", 0.0, 0.18)
	await t.finished
	l.queue_free()
