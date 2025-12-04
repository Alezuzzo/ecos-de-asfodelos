extends CanvasLayer

# Sinais para avisar a Arena qual botão foi pressionado
signal retry_pressed
signal quit_pressed

@onready var enemy_image: TextureRect = $Background/CenterContainer/VBoxContainer/EnemyImage
@onready var quote_label: Label = $Background/CenterContainer/VBoxContainer/QuoteLabel
@onready var progress_bar: ProgressBar = $Background/CenterContainer/VBoxContainer/ProgressBar
@onready var retry_button: Button = $Background/CenterContainer/VBoxContainer/RetryButton
@onready var quit_button: Button = $Background/CenterContainer/VBoxContainer/QuitButton

func _ready() -> void:
	# Configura foco nos botões
	if retry_button:
		retry_button.focus_mode = Control.FOCUS_ALL
		retry_button.mouse_entered.connect(func(): retry_button.grab_focus())
	if quit_button:
		quit_button.focus_mode = Control.FOCUS_ALL
		quit_button.mouse_entered.connect(func(): quit_button.grab_focus())

func _input(event: InputEvent) -> void:
	# Botão A do controle ativa o botão com foco
	if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_A and event.pressed:
		var focused = get_viewport().gui_get_focus_owner()
		if focused is Button:
			focused.emit_signal("pressed")
			get_viewport().set_input_as_handled()

func setup_screen(progress_percent: float, enemy_texture: Texture, quote: String):
	enemy_image.texture = enemy_texture
	quote_label.text = quote
	progress_bar.value = progress_percent
	show()
	# Foca no botão retry
	if retry_button:
		retry_button.grab_focus()

# Função do botão tentar nomente 
func _on_retry_button_pressed():
	emit_signal("retry_pressed")
	# Esconde a tela 
	hide()

# Função do botão Sair
func _on_quit_button_pressed():
	emit_signal("quit_pressed")
