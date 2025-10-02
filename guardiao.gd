# guardiao.gd
extends CharacterBody2D

signal morreu

#-----------------------------------------------------------------------------
# PAINEL DE CONTROLE DO CHEFE (Editável no Inspetor!)
#-----------------------------------------------------------------------------
@export_category("Atributos Principais")
@export var vida_maxima = 100
@export var velocidade = 120.0
@export var dano_por_toque = 2

@export_category("Balanceamento Fase 1")
@export var cooldown_ataque_f1 = 2.5 # Tempo entre ataques na Fase 1
@export var tempo_aviso_investida = 0.8 # Tempo de aviso antes do avanço
@export var multiplicador_vel_investida = 5.0 # Quão mais rápido é o avanço
@export var num_projeteis_salva = 7 # Quantidade de tiros no ataque em leque
@export var num_projeteis_circulo = 20 # Quantidade de tiros no ataque em círculo

@export_category("Balanceamento Fase 2")
@export var cooldown_ataque_f2 = 1.8 # Tempo entre ataques na Fase 2
@export var multiplicador_vel_f2 = 1.5 # Aumento de velocidade na Fase 2


#-----------------------------------------------------------------------------
# Variáveis de Controle (Não precisam ser mexidas)
#-----------------------------------------------------------------------------
var vida_atual
var jogador = null
var pode_causar_dano = true
var em_fase_2 = false
enum State {ESPERANDO, ATACANDO, AVANCANDO}
var estado_atual = State.ESPERANDO
var projetil_chefe_cena = preload("res://projetil_inimigo.tscn")

#-----------------------------------------------------------------------------
# Funções do Godot e Lógica de Estados (Não precisa mexer)
#-----------------------------------------------------------------------------
func _ready():
	vida_atual = vida_maxima
	$AtaqueCooldown.start(cooldown_ataque_f1) # Usa a nova variável

func _physics_process(delta):
	# (Esta função permanece igual à anterior)
	match estado_atual:
		State.ESPERANDO:
			if jogador:
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
				
#-----------------------------------------------------------------------------
# Lógica de Combate e Ataques (Atualizada com as variáveis)
#-----------------------------------------------------------------------------

func escolher_proximo_ataque():
	if estado_atual != State.ESPERANDO: return

	if not em_fase_2:
		var ataques_fase1 = [ataque_salva_de_ecos, ataque_investida_sombria, ataque_circulo_de_angustia]
		ataques_fase1.pick_random().call()
	else:
		var ataques_fase2 = [ataque_salva_espiral, ataque_investidas_multiplas, ataque_evocar_lamentos]
		ataques_fase2.pick_random().call()

# --- ATAQUES FASE 1 ---
func ataque_salva_de_ecos():
	estado_atual = State.ATACANDO
	var angulo_total = 80
	var angulo_inicial = -angulo_total / 2
	var angulo_passo = angulo_total / float(num_projeteis_salva - 1)
	
	for i in range(num_projeteis_salva):
		var projetil = projetil_chefe_cena.instantiate()
		projetil.position = position
		var angulo = deg_to_rad(angulo_inicial + (i * angulo_passo))
		projetil.rotation = global_position.direction_to(jogador.global_position).angle() + angulo
		get_parent().add_child(projetil)
	
	await get_tree().create_timer(1.0).timeout
	estado_atual = State.ESPERANDO
	$AtaqueCooldown.start(cooldown_ataque_f1)

func ataque_investida_sombria():
	estado_atual = State.AVANCANDO
	var alvo = jogador.global_position
	hit_flash() 
	await get_tree().create_timer(tempo_aviso_investida) # Usa a variável
	velocity = global_position.direction_to(alvo) * velocidade * multiplicador_vel_investida # Usa a variável
	await get_tree().create_timer(0.5).timeout
	velocity = Vector2.ZERO
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

# --- ATAQUES FASE 2 --- (as funções da fase 2 chamam as da fase 1, então são atualizadas automaticamente)
# ... (o resto das funções, como sofrer_dano, iniciar_fase_2, etc., permanecem iguais à versão anterior) ...
# (Cole o resto das funções da versão anterior aqui para completar)
# ...

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
	await get_tree().create_timer(0.5).timeout
	await ataque_investida_sombria_coroutine()
	
	estado_atual = State.ESPERANDO
	$AtaqueCooldown.start(cooldown_ataque_f2)

func ataque_investida_sombria_coroutine():
	estado_atual = State.AVANCANDO
	var alvo = jogador.global_position
	hit_flash()
	await get_tree().create_timer(tempo_aviso_investida)
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
