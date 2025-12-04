extends CanvasLayer

# Sinais para avisar a Arena qual botão foi pressionado
signal play_again_pressed
signal quit_pressed

# IMPORTANTE: O process_mode está configurado como ALWAYS na cena
# para que os botões funcionem mesmo com o jogo pausado

@onready var background: TextureRect = $Background
@onready var message_label: Label = $Background/CenterContainer/VBoxContainer/MessageLabel
@onready var play_again_button: Button = $Background/CenterContainer/VBoxContainer/ButtonsContainer/PlayAgainButton
@onready var quit_button: Button = $Background/CenterContainer/VBoxContainer/ButtonsContainer/QuitButton
@onready var victory_music_player: AudioStreamPlayer = $VictoryMusicPlayer

func _ready():
	# Conecta os sinais dos botões
	play_again_button.pressed.connect(_on_play_again_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Configura foco nos botões
	play_again_button.focus_mode = Control.FOCUS_ALL
	play_again_button.mouse_entered.connect(func(): play_again_button.grab_focus())
	quit_button.focus_mode = Control.FOCUS_ALL
	quit_button.mouse_entered.connect(func(): quit_button.grab_focus())

	# Inicialmente esconde a tela
	hide()

func _input(event: InputEvent) -> void:
	# Botão A do controle ativa o botão com foco
	if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_A and event.pressed:
		var focused = get_viewport().gui_get_focus_owner()
		if focused is Button:
			focused.emit_signal("pressed")
			get_viewport().set_input_as_handled()

func mostrar_tela():
	"""Mostra a tela de vitória"""
	show()
	# Foca no botão de jogar novamente
	play_again_button.grab_focus()

	# Toca a música de vitória (se houver um áudio configurado)
	if victory_music_player and victory_music_player.stream:
		victory_music_player.play()

# Função do botão Jogar Novamente
func _on_play_again_pressed():
	# Para a música de vitória
	if victory_music_player:
		victory_music_player.stop()
	emit_signal("play_again_pressed")
	hide()

# Função do botão Sair
func _on_quit_pressed():
	# Para a música de vitória
	if victory_music_player:
		victory_music_player.stop()
	emit_signal("quit_pressed")
	hide()
