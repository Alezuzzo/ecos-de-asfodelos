# inimigo.gd
extends CharacterBody2D

signal morreu

@export var velocidade = 150
@export var vida = 3
@export var dano_por_toque = 1 # Dano que ele causa ao tocar (1 = meio coração)

var jogador = null
var pode_causar_dano = true # Flag para controlar o cooldown

func sofrer_dano(dano):
	vida -= dano
	hit_flash()
	if vida <= 0:
		emit_signal("morreu")
		queue_free()

func hit_flash():
	var tween = create_tween()
	tween.tween_property($ColorRect, "modulate", Color.WHITE, 0.1)
	tween.tween_property($ColorRect, "modulate", Color(1,1,1,1), 0.1)

func _physics_process(delta):
	if jogador:
		var direcao = global_position.direction_to(jogador.global_position)
		velocity = direcao * velocidade
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()
	
	# --- LÓGICA DE DANO POR TOQUE ADICIONADA AQUI ---
	# Verifica se o inimigo colidiu com algo enquanto se movia
	for i in range(get_slide_collision_count()):
		var colisao = get_slide_collision(i)
		# Verifica se o corpo com que colidimos está no grupo "jogador"
		if colisao.get_collider().is_in_group("jogador"):
			# Se pudermos causar dano (o cooldown não está ativo)
			if pode_causar_dano:
				# Chama a função de dano no jogador
				colisao.get_collider().sofrer_dano(dano_por_toque)
				# Desativa a habilidade de causar dano e inicia o timer
				pode_causar_dano = false
				$DanoCooldown.start()

# Esta função será chamada quando o timer DanoCooldown terminar
func _on_dano_cooldown_timeout():
	pode_causar_dano = true # Permite que o inimigo cause dano novamente
