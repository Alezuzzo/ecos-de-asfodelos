extends Control

# Sinal emitido quando esta carta é escolhida. Ele envia o ID da carta.
signal card_chosen(id_carta)


# @onready para garantir que o script só pegue as referências
# quando a cena estiver completamente pronta.
@onready var card_texture: TextureRect = $CardTexture
@onready var card_animation: AnimatedSprite2D = $CardAnimation
@onready var card_name_label: Label = $CardNameLabel
@onready var description_label: Label = $DescriptionLabel
@onready var click_button: Button = $ClickButton

# Variável para guardar o ID da carta que esta instância está mostrando.
var card_id: String


func _ready():
	click_button.pressed.connect(_on_click_button_pressed)
	click_button.mouse_entered.connect(_on_mouse_entered_card)
	click_button.mouse_exited.connect(_on_mouse_exited_card)

# Função principal chamada pela TelaMelhorias pra configurar a carta.
func set_card_data(id_carta):
	self.card_id = id_carta
	var info = CardDB.get_card_info(id_carta)
	
	# Verificação de segurança: se a carta não tiver carta no DB, não faz nada.
	if not info: 
		print("ERRO em CardUI: Carta com ID '", id_carta, "' não encontrada no CardDB.")
		return
		
	# Configura os textos da carta.
	card_name_label.text = info["nome"]
	description_label.text = info["descricao"]
	description_label.hide() # A descrição começa escondida.
	
	# Reseta o estado visual, escondendo ambos os tipos de arte.
	card_texture.hide()
	card_animation.hide()
	
	# Decide qual nó visual mostrar com base nos dados do CardDB
	if info.has("animado") and info.animado == true:
		# Se a carta for animada, mostra e toca a animação.
		card_animation.show()
		var anim_name = id_carta + "_idle" 
		if card_animation.sprite_frames.has_animation(anim_name):
			card_animation.play(anim_name)
		else:
			print("AVISO em CardUI: Animação '", anim_name, "' não encontrada no SpriteFrames.")
	
	elif info.has("imagem"):
		# Se não for animada mas tiver imagem, mostra a imagem estática.
		card_texture.texture = load(info["imagem"])
		card_texture.show()

# --- (Callbacks) ---

func _on_click_button_pressed():
	# Avisa a TelaMelhorias que esta carta foi escolhida.
	emit_signal("card_chosen", card_id)

func _on_mouse_entered_card():
	# Mostra a descrição quando o mouse passa por cima
	description_label.show()

func _on_mouse_exited_card():
	# Esconde a descrição quando o mouse sai.
	description_label.hide()
