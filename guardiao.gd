# guardiao.gd
extends CharacterBody2D

signal morreu

#-----------------------------------------------------------------------------
# PAINEL DE CONTROLE DO CHEFE
#-----------------------------------------------------------------------------
@export_category("Atributos Principais")
@export var vida_maxima = 100
@export var velocidade = 120.0
@export var dano_por_toque = 2

@export_category("Balanceamento Fase 1")
@export var cooldown_ataque_f1 = 2.5
@export var tempo_aviso_investida = 0.8
@export var multiplicador_vel_investida = 5.0
@export var num_projeteis_salva = 7
@export var num_projeteis_circulo = 20

@export_category("Balanceamento Fase 2")
@export var cooldown_ataque_f2 = 1.8
@export var multiplicador_vel_f2 = 1.5

#-----------------------------------------------------------------------------
# Variáveis de Controle
#-----------------------------------------------------------------------------
var vida_atual
var jogador = null
var pode_causar_dano = true
var em_fase_2 = false
var tamanho_da_tela: Vector2
var metade_do_tamanho_sprite: Vector2
enum State {ESPERANDO, ATACANDO, AVANCANDO}
var estado_atual = State.ESPERANDO
var projetil_chefe_cena = preload("res://projetil_inimigo.tscn")

#-----------------------------------------------------------------------------
# Funções do Godot
#-----------------------------------------------------------------------------
func _ready():
	vida_atual = vida_maxima
	$AtaqueCooldown.start(cooldown_ataque_f1)
	tamanho_da_tela = get_viewport_rect().size
	metade_do_tamanho_sprite = $CollisionShape2D.shape.size / 2.0

func _physics_process(delta):
	# Se o jogador não existir mais, o chefe para.
	if not is_instance_valid(jogador):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	match estado_atual:
		State.ESPERANDO:
			var direcao = global_position.direction_to(jogador.global_position)
			velocity = direcao * (velocidade / 2)
			move_and_slide()
		State.AVANCANDO:
			move_and_slide()
		State.ATACANDO:
			velocity = Vector2.ZERO
			move_and_slide()
	
	for i in range(get_slide_collision_count()):
		var colisao = get_slide_collision(i)
		if colisao.get_collider().is_in_group("jogador"):
			if pode_causar_dano:
				colisao.get_collider().sofrer_dano(dano_por_toque)
				pode_causar_dano = false
				$DanoCooldown.start()
	
	global_position.x = clamp(global_position.x, metade_do_tamanho_sprite.x, tamanho_da_tela.x - metade_do_tamanho_sprite.x)
	global_position.y = clamp(global_position.y, metade_do_tamanho_sprite.y, tamanho_da_tela.y - metade_do_tamanho_sprite.y)

#-----------------------------------------------------------------------------
# Lógica de Combate e Ataques
#-----------------------------------------------------------------------------

func escolher_proximo_ataque():
	if not is_instance_valid(jogador): return
	if estado_atual != State.ESPERANDO: return
	if not em_fase_2:
		var ataques_fase1 = [ataque_salva_de_ecos, ataque_investida_sombria, ataque_circulo_de_angustia]
		ataques_fase1.pick_random().call()
	else:
		var ataques_fase2 = [ataque_salva_espiral, ataque_investidas_multiplas, ataque_evocar_lamentos]
		ataques_fase2.pick_random().call()

func ataque_salva_de_ecos():
	if not is_instance_valid(jogador): return
	estado_atual = State.ATACANDO
	var angulo_total = 80.0
	var angulo_inicial = -angulo_total / 2.0
	var angulo_passo = angulo_total / float(num_projeteis_salva - 1)
	var direcao_jogador = global_position.direction_to(jogador.global_position).angle()
	
	for i in range(num_projeteis_salva):
		var projetil = projetil_chefe_cena.instantiate()
		projetil.position = position
		var angulo = deg_to_rad(angulo_inicial + (i * angulo_passo))
		projetil.rotation = direcao_jogador + angulo
		get_parent().add_child(projetil)
	
	await get_tree().create_timer(1.0).timeout
	estado_atual = State.ESPERANDO
	$AtaqueCooldown.start(cooldown_ataque_f1)

func ataque_investida_sombria():
	await ataque_investida_sombria_coroutine()
	estado_atual = State.ESPERANDO
	$AtaqueCooldown.start(cooldown_ataque_f1)

func ataque_circulo_de_angustia():
	estado_atual = State.ATACANDO
	var angulo_passo = 360.0 / num_projeteis_circulo
	for i in range(num_projeteis_circulo):
		var projetil = projetil_chefe_cena.instantiate()
		projetil.position = position
		projetil.rotation_degrees = i * angulo_passo
		get_parent().add_child(projetil)
	
	await get_tree().create_timer(1.0).timeout
	estado_atual = State.ESPERANDO
	$AtaqueCooldown.start(cooldown_ataque_f1)

func ataque_salva_espiral():
	estado_atual = State.ATACANDO
	for i in range(20):
		var projetil = projetil_chefe_cena.instantiate()
		projetil.position = position
		projetil.rotation_degrees = i * 30
		projetil.velocidade = 200 + (i * 20)
		get_parent().add_child(projetil)
		await get_tree().create_timer(0.05).timeout
	
	estado_atual = State.ESPERANDO
	$AtaqueCooldown.start(cooldown_ataque_f2)
	
func ataque_investidas_multiplas():
	await ataque_investida_sombria_coroutine()
	if not is_instance_valid(jogador): return # Re-verifica depois da primeira investida
	await get_tree().create_timer(0.5).timeout
	if not is_instance_valid(jogador): return # Re-verifica depois da pausa
	await ataque_investida_sombria_coroutine()
	
	estado_atual = State.ESPERANDO
	$AtaqueCooldown.start(cooldown_ataque_f2)

func ataque_investida_sombria_coroutine():
	if not is_instance_valid(jogador): return
	estado_atual = State.AVANCANDO
	var alvo = jogador.global_position
	hit_flash()
	await get_tree().create_timer(tempo_aviso_investida)
	
	# Re-verifica se o jogador ainda existe DEPOIS da pausa do aviso
	if not is_instance_valid(jogador):
		estado_atual = State.ESPERANDO
		return
		
	velocity = global_position.direction_to(alvo) * velocidade * multiplicador_vel_investida
	await get_tree().create_timer(0.5).timeout
	velocity = Vector2.ZERO

func ataque_evocar_lamentos():
	estado_atual = State.ATACANDO
	if get_parent().has_method("spawnar_inimigo"):
		get_parent().spawnar_inimigo()
		get_parent().spawnar_inimigo()
	
	await get_tree().create_timer(1.0).timeout
	estado_atual = State.ESPERANDO
	$AtaqueCooldown.start(cooldown_ataque_f2)

#-----------------------------------------------------------------------------
# Lógica de Vida e Outros
#-----------------------------------------------------------------------------
func sofrer_dano(dano):
	vida_atual -= dano
	hit_flash()
	if vida_atual <= vida_maxima / 2 and not em_fase_2:
		iniciar_fase_2()
	if vida_atual <= 0:
		emit_signal("morreu")
		queue_free()

func iniciar_fase_2():
	print("CHEFE ENTROU NA FASE 2!")
	em_fase_2 = true
	velocidade *= multiplicador_vel_f2
	$ColorRect.color = Color.DARK_RED

func hit_flash():
	var tween = create_tween()
	tween.tween_property($ColorRect, "modulate", Color.WHITE, 0.1)
	tween.tween_property($ColorRect, "modulate", Color(1,1,1,1), 0.1)

func _on_dano_cooldown_timeout():
	pode_causar_dano = true

func _on_ataque_cooldown_timeout():
	escolher_proximo_ataque()
