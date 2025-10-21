# inimigo.gd
extends CharacterBody2D

signal morreu

@export var velocidade = 150
@export var vida = 3
@export var dano_por_toque = 1
@export var stop_distance = 30.0
@export var pushback_force = 600.0 # Aumentei um pouco a força padrão
@export var stun_duration = 0.4 # Aumentei a duração do stun pós-ataque

var jogador = null
var pode_causar_dano = true
var atordoado = false

#-----------------------------------------------------------------------------
# FUNÇÕES DE LÓGICA
#-----------------------------------------------------------------------------

func aplicar_repulsao(direcao, forca):
	if atordoado: return
	atordoado = true
	# move_and_collide para um empurrão instantâneo pela Onda de Choque
	move_and_collide(direcao * forca * get_physics_process_delta_time())
	$StunTimer.start(0.3) # Stun da Onda de Choque

func sofrer_dano(dano):
	vida -= dano
	hit_flash()
	if vida <= 0:
		emit_signal("morreu")
		queue_free()

func hit_flash():
	var tween = create_tween()
	var sprite_node = $AnimatedSprite2D if has_node("AnimatedSprite2D") else $ColorRect
	if sprite_node:
		tween.tween_property(sprite_node, "modulate", Color.WHITE, 0.1)
		tween.tween_property(sprite_node, "modulate", Color(1,1,1,1), 0.1)

#-----------------------------------------------------------------------------
# FUNÇÃO PRINCIPAL (_physics_process) - REVISADA
#-----------------------------------------------------------------------------

func _physics_process(delta):
	# --- VERIFICAÇÃO DE STUN PRIMEIRO ---
	# Se estiver atordoado, ZERA a velocidade e aplica o 'move_and_slide'
	# para resolver qualquer colisão residual, depois não faz mais nada.
	if atordoado:
		velocity = Vector2.ZERO
		move_and_slide() # Importante chamar mesmo parado para a física funcionar
		return
	# --- FIM DA VERIFICAÇÃO DE STUN ---

	# --- CÁLCULO DA VELOCIDADE DA IA ---
	# Só calcula a velocidade se NÃO estiver atordoado.
	if is_instance_valid(jogador):
		var direcao_para_jogador = global_position.direction_to(jogador.global_position)
		var distancia_para_jogador = global_position.distance_to(jogador.global_position)

		if distancia_para_jogador > stop_distance + 5:
			velocity = direcao_para_jogador * velocidade
		elif distancia_para_jogador < stop_distance - 5:
			velocity = -direcao_para_jogador * (velocidade / 2)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, velocidade * 3 * delta) # Freia mais rápido

	else: # Se o jogador não existe, para.
		velocity = Vector2.ZERO

	# Aplica o movimento calculado pela IA
	move_and_slide()
	# --- FIM DO CÁLCULO DA IA ---

	# --- VERIFICAÇÃO DE COLISÃO E PUSHBACK ---
	# Verifica colisões ocorridas APÓS o movimento principal
	for i in range(get_slide_collision_count()):
		var colisao = get_slide_collision(i)
		var collider = colisao.get_collider()

		if is_instance_valid(collider) and collider.is_in_group("jogador"):
			if pode_causar_dano:
				collider.sofrer_dano(dano_por_toque)
				pode_causar_dano = false
				$DanoCooldown.start()

				# --- EMPURRÃO PARA TRÁS REVISADO ---
				atordoado = true
				var push_direction = global_position.direction_to(collider.global_position).rotated(PI)
				
				# Usa move_and_collide para um empurrão instantâneo e físico
				var collision_info = move_and_collide(push_direction * pushback_force * delta)
				
				# Zera a velocidade logo após o empurrão físico
				velocity = Vector2.ZERO
				
				$StunTimer.start(stun_duration) # Usa a nova variável de duração
				# print(self.name, "atacou e foi empurrado.") # DEBUG
				break # Sai do loop após o primeiro ataque/pushback
				# --- FIM DO EMPURRÃO REVISADO ---

#-----------------------------------------------------------------------------
# FUNÇÕES CONECTADAS A SINAIS (Callbacks dos Timers)
#-----------------------------------------------------------------------------

func _on_dano_cooldown_timeout():
	pode_causar_dano = true

func _on_stun_timer_timeout():
	# print(self.name, "não está mais atordoado.") # DEBUG
	atordoado = false
