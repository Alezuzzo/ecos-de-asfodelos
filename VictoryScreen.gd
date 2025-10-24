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

func _ready():
	# Conecta os sinais dos botões
	play_again_button.pressed.connect(_on_play_again_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Inicialmente esconde a tela
	hide()

func mostrar_tela():
	"""Mostra a tela de vitória"""
	show()
	# Foca no botão de jogar novamente
	play_again_button.grab_focus()

# Função do botão Jogar Novamente
func _on_play_again_pressed():
	emit_signal("play_again_pressed")
	hide()

# Função do botão Sair
func _on_quit_pressed():
	emit_signal("quit_pressed")
	hide()
