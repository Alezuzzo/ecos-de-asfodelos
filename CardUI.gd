# CardUI.gd
extends Control

signal card_chosen(id_carta)

@onready var card_texture = $CardTexture
@onready var card_name_label = $CardNameLabel
@onready var description_label = $DescriptionLabel # <-- NOVA REFERÊNCIA
@onready var click_button = $ClickButton

var card_id: String

func _ready():
	click_button.pressed.connect(_on_click_button_pressed)

	# Conecta os sinais de mouse_entered e mouse_exited do botão
	# para todo o controle de card_ui
	click_button.mouse_entered.connect(_on_mouse_entered_card) # <-- NOVO
	click_button.mouse_exited.connect(_on_mouse_exited_card)   # <-- NOVO

func set_card_data(id_carta):
	self.card_id = id_carta
	var info = CardDB.get_card_info(id_carta)

	if info:
		card_name_label.text = info["nome"]
		if info.has("imagem"):
			card_texture.texture = load(info["imagem"])

		# Define a descrição e a mantém escondida inicialmente
		description_label.text = info["descricao"] # <-- NOVO
		description_label.hide() # Garante que está escondida
	else:
		print("Erro: Carta com ID ", id_carta, " não encontrada no CardDB.")

func _on_click_button_pressed():
	emit_signal("card_chosen", card_id)

# --- NOVAS FUNÇÕES DE MOUSE ---
func _on_mouse_entered_card():
	description_label.show() # Mostra a descrição ao entrar com o mouse

func _on_mouse_exited_card():
	description_label.hide() # Esconde a descrição ao sair com o mouse
