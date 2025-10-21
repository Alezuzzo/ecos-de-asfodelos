# atirador.gd
extends CharacterBody2D

signal morreu

# --- Variáveis Editáveis no Inspetor ---
@export var velocidade = 100
@export var distancia_ideal = 300 # Distância que ele tenta manter do jogador
@export var cadencia_tiro = 1.5   # Tempo entre os tiros
@export var vida = 2

# --- Variáveis Internas ---
var jogador = null
var pode_atirar = true
var atordoado = false # <-- ADICIONADO: Para stun da onda de choque/repulsão

var projetil_inimigo_cena = preload("res://projetil_inimigo.tscn")

#-----------------------------------------------------------------------------
# FUNÇÕES DE LÓGICA
#-----------------------------------------------------------------------------

# Função chamada pela Onda de Choque
func aplicar_repulsao(direcao, forca):
	if atordoado: return
	atordoado = true
	move_and_collide(direcao * forca * get_physics_process_delta_time())
	$StunTimer.start(0.3) # Duração do stun da Onda de Choque

func sofrer_dano(dano):
	vida -= dano
	hit_flash() # Chama o efeito visual
	if vida <= 0:
		emit_signal("morreu")
		queue_free()

# --- FUNÇÃO HIT_FLASH CORRIGIDA ---
func hit_flash():
	var tween = create_tween()
	# Tenta encontrar o nó visual correto (Sprite ou ColorRect)
	var sprite_node = $AnimatedSprite2D if has_node("AnimatedSprite2D") else ($Sprite2D if has_node("Sprite2D") else $ColorRect)
	if is_instance_valid(sprite_node): # Só aplica se encontrar o nó
		tween.tween_property(sprite_node, "modulate", Color.WHITE, 0.1)
		tween.tween_property(sprite_node, "modulate", Color(1,1,1,1), 0.1)
	else:
		print("AVISO em Atirador: Nó visual não encontrado para hit_flash.")
# --- FIM DA CORREÇÃO ---

#-----------------------------------------------------------------------------
# FUNÇÃO PRINCIPAL (_physics_process)
#-----------------------------------------------------------------------------

func _physics_process(delta):
	# --- LÓGICA DE STUN ADICIONADA ---
	# Se estiver atordoado, para tudo e sai da função.
	if atordoado:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	# --- FIM DA LÓGICA DE STUN ---

	# Lógica de Movimento e Tiro (só executa se não estiver atordoado)
	if is_instance_valid(jogador):
		var direcao_para_jogador = global_position.direction_to(jogador.global_position)
		var distancia = global_position.distance_to(jogador.global_position)

		# Lógica de movimento para manter distância
		if distancia > distancia_ideal + 20: # Se estiver muito longe, aproxima-se
			velocity = direcao_para_jogador * velocidade
		elif distancia < distancia_ideal - 20: # Se estiver muito perto, afasta-se
			velocity = -direcao_para_jogador * velocidade
		else: # Se estiver na distância ideal, para de se mover e tenta atirar
			velocity = velocity.move_toward(Vector2.ZERO, velocidade * 2 * delta) # Freia
			if pode_atirar:
				atirar()

	else: # Se o jogador não existe, para.
		velocity = Vector2.ZERO

	move_and_slide() # Aplica o movimento calculado

#-----------------------------------------------------------------------------
# FUNÇÃO DE TIRO
#-----------------------------------------------------------------------------

func atirar():
	# Verifica se o jogador ainda existe antes de atirar
	if not is_instance_valid(jogador): return

	pode_atirar = false

	var projetil = projetil_inimigo_cena.instantiate()
	projetil.position = position
	# Faz o projétil olhar na direção do jogador no momento do disparo
	projetil.look_at(jogador.global_position)

	# Adiciona o projétil à cena principal (pai do atirador)
	get_parent().add_child(projetil)

	# Usa um Timer para controlar a cadência
	$TiroTimer.start(cadencia_tiro)

#-----------------------------------------------------------------------------
# FUNÇÕES DE SINAIS (Callbacks dos Timers)
#-----------------------------------------------------------------------------

# Chamada quando o timer de tiro termina
func _on_tiro_timer_timeout():
	pode_atirar = true

# --- FUNÇÃO DE STUN ADICIONADA ---
# Chamada quando o timer de stun termina
func _on_stun_timer_timeout():
	atordoado = false
# --- FIM DA FUNÇÃO DE STUN ---
