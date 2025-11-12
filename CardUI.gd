extends Control

signal card_chosen(id_carta)

@onready var card_texture: TextureRect = $CardTexture
@onready var card_animation: AnimatedSprite2D = $CardAnimation
@onready var card_name_label: Label = $CardNameLabel
@onready var description_label: Label = $DescriptionLabel
@onready var click_button: Button = $ClickButton

var card_id: String
var is_burning = false
var burn_material: ShaderMaterial


func _ready():
	click_button.pressed.connect(_on_click_button_pressed)
	click_button.mouse_entered.connect(_on_mouse_entered_card)
	click_button.mouse_exited.connect(_on_mouse_exited_card)

func set_card_data(id_carta):
	reset_card_state()

	self.card_id = id_carta
	var info = CardDB.get_card_info(id_carta)

	if not info:
		print("ERRO em CardUI: Carta com ID '", id_carta, "' não encontrada no CardDB.")
		return

	card_name_label.text = info["nome"]
	description_label.text = info["descricao"]
	description_label.hide()

	card_texture.hide()
	card_animation.hide()

	if info.has("animado") and info.animado == true:
		card_animation.show()
		var anim_name = id_carta + "_idle"
		if card_animation.sprite_frames.has_animation(anim_name):
			card_animation.play(anim_name)
	elif info.has("imagem"):
		card_texture.texture = load(info["imagem"])
		card_texture.show()

func _on_click_button_pressed():
	if is_burning:
		return
	start_burn_effect()

func _on_mouse_entered_card():
	description_label.show()

func _on_mouse_exited_card():
	description_label.hide()

func reset_card_state():
	is_burning = false
	click_button.disabled = false
	rotation_degrees = 0
	scale = Vector2.ONE

	if card_texture.material:
		card_texture.material = null
	if card_animation.material:
		card_animation.material = null
	if card_name_label.material:
		card_name_label.material = null

	show()
	modulate = Color(1, 1, 1, 1)

func start_burn_effect():
	is_burning = true
	click_button.disabled = true

	if not burn_material:
		burn_material = ShaderMaterial.new()
		var shader = load("res://shaders/burn_effect.gdshader")
		if shader:
			burn_material.shader = shader

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

	if card_texture.visible:
		card_texture.material = burn_material
	elif card_animation.visible:
		card_animation.material = burn_material

	card_name_label.material = burn_material.duplicate()

	var tween = create_tween()
	tween.set_parallel(true)

	tween.tween_method(func(value):
		if burn_material:
			burn_material.set_shader_parameter("dissolve_progress", value)
		if card_name_label.material:
			card_name_label.material.set_shader_parameter("dissolve_progress", value)
	, 0.0, 1.1, 2.0)

	tween.tween_property(self, "rotation_degrees", randf_range(-8, 8), 2.0).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 2.0).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(1.5)

	await tween.finished
	emit_signal("card_chosen", card_id)
