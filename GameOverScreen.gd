# GameOverScreen.gd
extends CanvasLayer

# Sinais para avisar a Arena qual botão foi pressionado
signal retry_pressed
signal quit_pressed

@onready var enemy_image: TextureRect = $Background/CenterContainer/VBoxContainer/EnemyImage
@onready var quote_label: Label = $Background/CenterContainer/VBoxContainer/QuoteLabel
@onready var progress_bar: ProgressBar = $Background/CenterContainer/VBoxContainer/ProgressBar

func setup_screen(progress_percent: float, enemy_texture: Texture, quote: String):
	enemy_image.texture = enemy_texture
	quote_label.text = quote
	progress_bar.value = progress_percent
	show()

# Esta função é chamada quando o botão Tentar Novamente é pressionado
func _on_retry_button_pressed():
	# Emite o sinal para a Arena ouvir
	emit_signal("retry_pressed")
	# Esconde a tela para que o jogador não possa clicar de novo
	hide()

# Esta função é chamada quando o botão Sair é pressionado
func _on_quit_button_pressed():
	# Emite o sinal para a Arena ouvir
	emit_signal("quit_pressed")
