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
@export var stop_distance = 50.0
@export var pushback_force = 700.0
@export var stun_duration_pos_ataque = 0.6

@export_category("Balanceamento Fase 1")
@export var cooldown_ataque_f1 = 2.5
@export var tempo_aviso_investida = 0.8
@export var multiplicador_vel_investida = 5.0
@export var num_projeteis_salva = 12
@export var num_projeteis_circulo = 28

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
var invulneravel = false # Durante transição
var atordoado = false # Para stun pós-ataque

@onready var sprite_animado: AnimatedSprite2D = $SpriteAnimado

enum State {ESPERANDO, ATACANDO, AVANCANDO}
var estado_atual = State.ESPERANDO
var projetil_chefe_cena = preload("res://projetil_inimigo.tscn")
var damage_number_scene = preload("res://DamageNumber.tscn") # <-- REFERÊNCIA ADICIONADA
var tamanho_da_tela: Vector2
var metade_do_tamanho_sprite: Vector2

#-----------------------------------------------------------------------------
# Funções do Godot
#-----------------------------------------------------------------------------
func _ready():
	vida_atual = vida_maxima
	$AtaqueCooldown.start(cooldown_ataque_f1)
	tamanho_da_tela = get_viewport_rect().size
	if has_node("CollisionShape2D") and $CollisionShape2D.shape:
		if $CollisionShape2D.shape is CapsuleShape2D:
			metade_do_tamanho_sprite = Vector2($CollisionShape2D.shape.radius, $CollisionShape2D.shape.height / 2.0)
		elif $CollisionShape2D.shape is RectangleShape2D:
			metade_do_tamanho_sprite = $CollisionShape2D.shape.size / 2.0
		else:
			metade_do_tamanho_sprite = Vector2.ZERO
	else:
		metade_do_tamanho_sprite = Vector2.ZERO
		print("AVISO em Guardiao: CollisionShape2D não encontrado ou sem shape.")

func _physics_process(delta):
	if atordoado or invulneravel or not is_instance_valid(jogador):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var mover_neste_frame = true
	match estado_atual:
		State.ESPERANDO:
			var direcao_para_jogador = global_position.direction_to(jogador.global_position)
			var distancia_para_jogador = global_position.distance_to(jogador.global_position)
			if distancia_para_jogador > stop_distance + 10:
				velocity = direcao_para_jogador * (velocidade / 2)
			elif distancia_para_jogador < stop_distance - 10:
				velocity = -direcao_para_jogador * (velocidade / 3)
			else:
				velocity = velocity.move_toward(Vector2.ZERO, velocidade * 3 * delta)
		State.AVANCANDO:
			pass
		State.ATACANDO:
			velocity = Vector2.ZERO
			mover_neste_frame = false
	
	if mover_neste_frame:
		move_and_slide()

	for i in range(get_slide_collision_count()):
		var colisao = get_slide_collision(i)
		var collider = colisao.get_collider()
		if is_instance_valid(collider) and collider.is_in_group("jogador"):
			if pode_causar_dano:
				collider.sofrer_dano(dano_por_toque)
				pode_causar_dano = false
				if has_node("DanoCooldown"): $DanoCooldown.start()
				else: print("AVISO em Guardiao: Nó DanoCooldown não encontrado.")
				
				atordoado = true
				var push_direction = global_position.direction_to(collider.global_position).rotated(PI)
				move_and_collide(push_direction * pushback_force * delta)
				velocity = Vector2.ZERO
				if has_node("StunTimer"): $StunTimer.start(stun_duration_pos_ataque)
				else: print("AVISO em Guardiao: Nó StunTimer não encontrado.")
				break

	if metade_do_tamanho_sprite != Vector2.ZERO:
		global_position.x = clamp(global_position.x, metade_do_tamanho_sprite.x, tamanho_da_tela.x - metade_do_tamanho_sprite.x)
		global_position.y = clamp(global_position.y, metade_do_tamanho_sprite.y, tamanho_da_tela.y - metade_do_tamanho_sprite.y)

#-----------------------------------------------------------------------------
# Lógica de Vida e Fases
#-----------------------------------------------------------------------------
func sofrer_dano(dano):
	if invulneravel: return

	# --- CÓDIGO DO NÚMERO DE DANO ADICIONADO ---
	if damage_number_scene:
		var damage_num = damage_number_scene.instantiate()
		get_parent().add_child(damage_num)
		damage_num.global_position = global_position + Vector2(randf_range(-20, 20), -60) # Ajuste o Y (-60)
		damage_num.set_damage(dano)
	# --- FIM DA ADIÇÃO ---

	vida_atual -= dano
	hit_flash()
	if vida_atual <= vida_maxima / 2 and not em_fase_2:
		call_deferred("iniciar_fase_2")
	if vida_atual <= 0 and not is_queued_for_deletion():
		emit_signal("morreu")
		queue_free()

func iniciar_fase_2():
	if em_fase_2: return
	print("CHEFE INICIANDO TRANSIÇÃO PARA A FASE 2!")
	em_fase_2 = true
	invulneravel = true
	estado_atual = State.ESPERANDO
	velocity = Vector2.ZERO
	sprite_animado.play("transicao")
	await sprite_animado.animation_finished
	print("TRANSIÇÃO COMPLETA! FASE 2 COMEÇOU!")
	velocidade *= multiplicador_vel_f2
	invulneravel = false
	sprite_animado.play("fase_2_idle")
	$AtaqueCooldown.start(cooldown_ataque_f2)

func hit_flash():
	var tween = create_tween()
	tween.tween_property(sprite_animado, "modulate", Color.WHITE, 0.1)
	tween.tween_property(sprite_animado, "modulate", Color(1,1,1,1), 0.1)

#-----------------------------------------------------------------------------
# Lógica de Combate e Ataques
#-----------------------------------------------------------------------------
# ... (Funções escolher_proximo_ataque e todos os ataques permanecem iguais) ...
func escolher_proximo_ataque():
	if not is_instance_valid(jogador) or estado_atual != State.ESPERANDO or atordoado:
		return

	if not em_fase_2:
		var ataques_fase1 = [ataque_salva_de_ecos, ataque_investida_sombria, ataque_circulo_de_angustia]
		ataques_fase1.pick_random().call()
	else:
		var ataques_fase2 = [ataque_salva_espiral, ataque_investidas_multiplas, ataque_evocar_lamentos]
		ataques_fase2.pick_random().call()

func ataque_evocar_lamentos():
	estado_atual = State.ATACANDO
	var arena_node = get_parent().get_parent()
	if arena_node.has_method("spawnar_inimigo_para_chefe"):
		arena_node.spawnar_inimigo_para_chefe()
		arena_node.spawnar_inimigo_para_chefe()
	else:
		print("ERRO em Guardiao: Função spawnar_inimigo_para_chefe não encontrada na Arena.")
	await get_tree().create_timer(1.0).timeout
	estado_atual = State.ESPERANDO
	$AtaqueCooldown.start(cooldown_ataque_f2)

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
	if not is_instance_valid(jogador): return
	await get_tree().create_timer(0.5).timeout
	if not is_instance_valid(jogador): return
	await ataque_investida_sombria_coroutine()
	estado_atual = State.ESPERANDO
	$AtaqueCooldown.start(cooldown_ataque_f2)

func ataque_investida_sombria_coroutine():
	if not is_instance_valid(jogador): return
	estado_atual = State.AVANCANDO
	var alvo = jogador.global_position
	hit_flash()
	await get_tree().create_timer(tempo_aviso_investida)
	if not is_instance_valid(jogador):
		estado_atual = State.ESPERANDO
		return
	velocity = global_position.direction_to(alvo) * velocidade * multiplicador_vel_investida
	await get_tree().create_timer(0.5).timeout
	velocity = Vector2.ZERO
#-----------------------------------------------------------------------------
# FUNÇÕES DE SINAIS (Callbacks)
#-----------------------------------------------------------------------------
func _on_dano_cooldown_timeout():
	pode_causar_dano = true

func _on_ataque_cooldown_timeout():
	escolher_proximo_ataque()

func _on_stun_timer_timeout():
	atordoado = false
	$AtaqueCooldown.start(cooldown_ataque_f1 if not em_fase_2 else cooldown_ataque_f2)
