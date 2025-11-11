extends CanvasLayer

# Referências dos nós (serão definidas no _ready)
@onready var item_resume: HBoxContainer = $Background/CenterContainer/VBox/ItemResume
@onready var item_volume: HBoxContainer = $Background/CenterContainer/VBox/ItemVolume
@onready var item_quit: HBoxContainer = $Background/CenterContainer/VBox/ItemQuit

@onready var resume_button: Button = item_resume.get_node("ResumeButton")
@onready var volume_slider: HSlider = item_volume.get_node("VolumeSlider")
@onready var volume_label: Label = item_volume.get_node("VolumeLabel")
@onready var quit_button: Button = item_quit.get_node("QuitButton")

@onready var arrow_resume: Label = item_resume.get_node("ArrowResume")
@onready var arrow_volume: Label = item_volume.get_node("ArrowVolume")
@onready var arrow_quit: Label = item_quit.get_node("ArrowQuit")

@onready var background: ColorRect = $Background
@onready var title_label: Label = $Background/CenterContainer/VBox/TitleLabel

var is_paused = false

func _ready() -> void:
	# IMPORTANTE: Configurar para funcionar durante pause
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Inicialmente escondido
	hide()

	# Configurar setas (estilo similar ao MainMenu)
	for arrow in [arrow_resume, arrow_volume, arrow_quit]:
		if arrow == null: continue
		if arrow.text.strip_edges() == "": arrow.text = "▶"
		arrow.visible = false
		if arrow.custom_minimum_size == Vector2.ZERO:
			arrow.custom_minimum_size = Vector2(32, 32)
		arrow.pivot_offset = arrow.size / 2.0
		arrow.resized.connect(func(): arrow.pivot_offset = arrow.size / 2.0)

	# Configurar botões
	for btn in [resume_button, quit_button]:
		if btn == null: continue
		btn.flat = true
		btn.focus_mode = Control.FOCUS_ALL
		btn.mouse_entered.connect(func(): btn.grab_focus())

	# Conectar foco às setas
	_wire_arrow(resume_button, arrow_resume)
	_wire_arrow(quit_button, arrow_quit)

	# Conectar ações dos botões
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Configurar slider de volume
	volume_slider.min_value = 0.0
	volume_slider.max_value = 100.0
	volume_slider.step = 5.0
	volume_slider.value = 100.0
	volume_slider.value_changed.connect(_on_volume_changed)
	volume_slider.focus_mode = Control.FOCUS_ALL
	volume_slider.mouse_entered.connect(func(): volume_slider.grab_focus())

	# Conectar foco do slider à seta
	volume_slider.focus_entered.connect(func():
		arrow_volume.visible = true
		_tint(volume_label, Color(0.95, 0.85, 0.55))
	)
	volume_slider.focus_exited.connect(func():
		arrow_volume.visible = false
		_tint(volume_label, Color.WHITE)
	)

	# Atualizar label inicial do volume
	_update_volume_label(volume_slider.value)

func _wire_arrow(btn: Button, arrow: Label) -> void:
	if btn == null or arrow == null: return
	btn.focus_entered.connect(func():
		arrow.visible = true
		_tint(btn, Color(0.95, 0.85, 0.55))  # dourado suave
	)
	btn.focus_exited.connect(func():
		arrow.visible = false
		_tint(btn, Color.WHITE)
	)

func _tint(node: CanvasItem, col: Color) -> void:
	var tw := create_tween()
	tw.tween_property(node, "modulate", col, 0.08)

func _input(event: InputEvent) -> void:
	# ESC para pausar/despausar
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused

	if is_paused:
		show()
		resume_button.grab_focus()
		# Animação suave de fade in
		background.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(background, "modulate:a", 1.0, 0.15)
	else:
		hide()

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_volume_changed(value: float) -> void:
	# Ajusta o volume do AudioServer (Master bus)
	var volume_db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)
	_update_volume_label(value)

func _update_volume_label(value: float) -> void:
	volume_label.text = "VOLUME: %d%%" % int(value)

func _on_quit_pressed() -> void:
	# Volta ao menu principal
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")
