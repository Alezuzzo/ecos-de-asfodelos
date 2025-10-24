extends Area2D

@export var forca_repulsao = 600.0
@export var raio_final = 300.0
@export var duracao = 0.4

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	collision_shape.disabled = true
	scale = Vector2.ZERO
	modulate.a = 0.5
	
	# Garante que a sprite esteja visível antes da animação
	sprite.visible = true
	
	animar_onda()

func _on_body_entered(body):
	if body.is_in_group("inimigos"):
		if body.has_method("aplicar_repulsao"):
			var direcao = global_position.direction_to(body.global_position)
			body.aplicar_repulsao(direcao, forca_repulsao)


# FUNÇÕES CUSTOMIZADAS

func animar_onda():
	await get_tree().create_timer(0.05).timeout
	collision_shape.disabled = false
	
	var tween = create_tween().set_parallel(true)
	
	var frame_width = 1.0
	if sprite.sprite_frames and sprite.sprite_frames.get_frame_count(sprite.animation) > 0:
		var frame_texture = sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
		if frame_texture: # Verifica se a textura foi encontrada
			frame_width = frame_texture.get_width()

	tween.tween_property(self, "scale", Vector2.ONE * (raio_final * 2.0 / max(frame_width, 1.0)), duracao)
	tween.tween_property(self, "modulate:a", 0, duracao).from(0.5)
	
	# Garante que a animação seja tocada
	sprite.play()

	await tween.finished
	queue_free() # Destrói a cena da onda de choque
