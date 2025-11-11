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
@onready var burn_particles: GPUParticles2D = $BurnParticles

# Variável para guardar o ID da carta que esta instância está mostrando.
var card_id: String
var is_burning = false

# Material shader para efeito de queima
var burn_material: ShaderMaterial


func _ready():
	click_button.pressed.connect(_on_click_button_pressed)
	click_button.mouse_entered.connect(_on_mouse_entered_card)
	click_button.mouse_exited.connect(_on_mouse_exited_card)

# Função principal chamada pela TelaMelhorias pra configurar a carta.
func set_card_data(id_carta):
	# IMPORTANTE: Reseta o estado visual completo da carta antes de configurar
	reset_card_state()

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
	if is_burning:
		return

	# Inicia o efeito de queima antes de emitir o sinal
	start_burn_effect()

func _on_mouse_entered_card():
	# Mostra a descrição quando o mouse passa por cima
	description_label.show()

func _on_mouse_exited_card():
	# Esconde a descrição quando o mouse sai.
	description_label.hide()

# Reseta o estado visual completo da carta
func reset_card_state():
	# Reseta flags
	is_burning = false
	click_button.disabled = false

	# Reseta transformações
	rotation_degrees = 0
	scale = Vector2.ONE

	# Remove materiais shader antigos
	if card_texture.material:
		card_texture.material = null
	if card_animation.material:
		card_animation.material = null
	if card_name_label.material:
		card_name_label.material = null

	# Para e reseta partículas
	if burn_particles:
		burn_particles.emitting = false
		burn_particles.restart()

	# Mostra a carta novamente (caso estivesse escondida)
	show()
	modulate = Color(1, 1, 1, 1) # Reseta cor e alpha

# Inicia o efeito de queima da carta
func start_burn_effect():
	is_burning = true
	click_button.disabled = true

	# Cria o material shader se ainda não existe
	if not burn_material:
		burn_material = ShaderMaterial.new()
		var shader = load("res://shaders/burn_effect.gdshader")
		if shader:
			burn_material.shader = shader

			# Cria textura de ruído procedural
			var noise_texture = NoiseTexture2D.new()
			var noise = FastNoiseLite.new()
			noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
			noise.frequency = 0.05
			noise_texture.noise = noise
			noise_texture.width = 256
			noise_texture.height = 256

			burn_material.set_shader_parameter("noise_texture", noise_texture)
			burn_material.set_shader_parameter("dissolve_progress", 0.0)
			burn_material.set_shader_parameter("edge_thickness", 0.1)
			burn_material.set_shader_parameter("edge_color1", Vector3(1.0, 0.4, 0.0))
			burn_material.set_shader_parameter("edge_color2", Vector3(0.9, 0.0, 0.0))
			burn_material.set_shader_parameter("noise_scale", 4.0)
			burn_material.set_shader_parameter("distortion_strength", 0.2)

	# Aplica o material ao elemento visual correto
	if card_texture.visible:
		card_texture.material = burn_material
	elif card_animation.visible:
		card_animation.material = burn_material

	# Também aplica no label do nome
	card_name_label.material = burn_material.duplicate()

	# Inicia partículas de fogo/cinzas
	if burn_particles:
		burn_particles.emitting = true

	# Anima o progresso da queima
	var tween = create_tween()
	tween.set_parallel(true)

	# Anima o shader
	tween.tween_method(func(value):
		if burn_material:
			burn_material.set_shader_parameter("dissolve_progress", value)
		if card_name_label.material:
			card_name_label.material.set_shader_parameter("dissolve_progress", value)
	, 0.0, 1.1, 2.0)

	# Anima a rotação e escala para mais dramatismo
	tween.tween_property(self, "rotation_degrees", randf_range(-8, 8), 2.0).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 2.0).set_ease(Tween.EASE_IN)

	# Fade out final para sumir completamente
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(1.5)

	# Aguarda a animação terminar
	await tween.finished

	# Para as partículas
	if burn_particles:
		burn_particles.emitting = false

	# Emite o sinal para a TelaMelhorias que a carta foi escolhida
	emit_signal("card_chosen", card_id)
