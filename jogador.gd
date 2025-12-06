extends CharacterBody2D

signal saude_alterada(saude_atual, saude_maxima)
signal morreu


@export var velocidade = 300
@export var cadencia_tiro = 0.25
@export var dano_projetil = 1
@export var saude_maxima = 6
var saude_atual = 0


var projetil_cena = preload("res://projetil.tscn")
var onda_de_choque_cena = preload("res://onda_de_choque.tscn")
var hud = null
var damage_overlay_scene = null 


@onready var shot_sound_player = $ShotSoundPlayer
@onready var sprite_animado = $AnimatedSprite2D

var pode_atirar = true
var ultima_direcao_tiro = Vector2.RIGHT
var esta_atirando_agora = false
var cartas_coletadas = []

# Afinidade da Resiliência
var tem_guardiao_caido = false
var tem_foco_penitente = false
var foco_penitente_ativo = false
var tem_baluarte_da_alma = false
var baluarte_usado_na_onda = false
var invulneravel = false

# Afinidade do Espectro
var projeteis_perfurantes = false
var chance_esquiva = 0.0
var tem_ecos_desafiante = false

# Cartas Corrompidas
var pode_curar = true
var projeteis_teleguiados = false

func _ready():
	saude_atual = saude_maxima
	emit_signal("saude_alterada", saude_atual, saude_maxima)
	
	# --- BUSCA A CENA DE DANO NA ARENA ---
	# Procura por um nó chamado "DamageOverlayScene" (ou similar) no pai (Arena)
	# Se você deu outro nome para a cena na Arena, ajuste o nome abaixo.
	damage_overlay_scene = get_parent().get_node_or_null("DamageOverlayScene")
	if not damage_overlay_scene:
		# Tenta buscar pelo tipo se o nome falhar (mais robusto)
		for filho in get_parent().get_children():
			if filho.name.begins_with("DamageOverlay"):
				damage_overlay_scene = filho
				break
	# -------------------------------------

func _physics_process(_delta): # Usei _delta para sumir com o aviso amarelo
	if tem_foco_penitente and not $FocoTimer.is_stopped():
		var progresso = 1.0 - ($FocoTimer.time_left / $FocoTimer.wait_time)
		if hud: hud.atualizar_timer_foco(progresso)

	esta_atirando_agora = Input.is_action_pressed("shoot_up") or \
						  Input.is_action_pressed("shoot_down") or \
						  Input.is_action_pressed("shoot_left") or \
						  Input.is_action_pressed("shoot_right") or \
						  Input.is_joy_button_pressed(0, JOY_BUTTON_A) or \
						  Input.is_joy_button_pressed(0, JOY_BUTTON_B) or \
						  Input.is_joy_button_pressed(0, JOY_BUTTON_X) or \
						  Input.is_joy_button_pressed(0, JOY_BUTTON_Y)

	handle_movimento()
	handle_tiro()
	handle_animacao()
	clamp_position_to_screen()

func handle_movimento():
	var direcao = Input.get_vector("esquerda", "direita", "cima", "baixo")

	var gamepad_move = Vector2(
		Input.get_joy_axis(0, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	)

	if gamepad_move.length() > 0.2:
		direcao = gamepad_move.normalized()

	velocity = direcao * velocidade
	move_and_slide()

func handle_tiro():
	if not pode_atirar: return

	if Input.is_joy_button_pressed(0, JOY_BUTTON_A):
		atirar(Vector2.DOWN); return
	elif Input.is_joy_button_pressed(0, JOY_BUTTON_B):
		atirar(Vector2.RIGHT); return
	elif Input.is_joy_button_pressed(0, JOY_BUTTON_X):
		atirar(Vector2.LEFT); return
	elif Input.is_joy_button_pressed(0, JOY_BUTTON_Y):
		atirar(Vector2.UP); return

	if Input.is_action_pressed("shoot_up"): atirar(Vector2.UP)
	elif Input.is_action_pressed("shoot_down"): atirar(Vector2.DOWN)
	elif Input.is_action_pressed("shoot_left"): atirar(Vector2.LEFT)
	elif Input.is_action_pressed("shoot_right"): atirar(Vector2.RIGHT)

func handle_animacao():
	if velocity.length() > 0:
		if velocity.y > 0: sprite_animado.play("walk_down")
		elif velocity.y < 0: sprite_animado.play("walk_up")
		else: sprite_animado.play("walk_side")
	else:
		if ultima_direcao_tiro.y < 0: sprite_animado.play("walk_up")
		elif ultima_direcao_tiro.y > 0: sprite_animado.play("walk_down")
		else: sprite_animado.play("idle")
	
	if esta_atirando_agora:
		if ultima_direcao_tiro.x < 0: sprite_animado.flip_h = true
		elif ultima_direcao_tiro.x > 0: sprite_animado.flip_h = false
	elif velocity.x != 0:
		if velocity.x < 0: sprite_animado.flip_h = true
		elif velocity.x > 0: sprite_animado.flip_h = false

func clamp_position_to_screen():
	var tamanho_da_tela = get_viewport_rect().size
	var collision_shape_node = $CollisionShape2D
	if is_instance_valid(collision_shape_node) and is_instance_valid(collision_shape_node.shape):
		var shape = collision_shape_node.shape
		var metade_largura = shape.radius if shape is CapsuleShape2D else shape.size.x / 2.0
		var metade_altura = shape.height / 2.0 if shape is CapsuleShape2D else shape.size.y / 2.0
		global_position.x = clamp(global_position.x, metade_largura, tamanho_da_tela.x - metade_largura)
		global_position.y = clamp(global_position.y, metade_altura, tamanho_da_tela.y - metade_altura)


func atirar(direcao_tiro: Vector2):
	if shot_sound_player: shot_sound_player.play()
	pode_atirar = false
	ultima_direcao_tiro = direcao_tiro
	
	criar_projetil(direcao_tiro, dano_projetil, 1.0, true)
	
	if tem_ecos_desafiante:
		disparar_eco(direcao_tiro)

	$TimerCadencia.start(cadencia_tiro)

func criar_projetil(direcao: Vector2, dano_base: int, escala: float, aplica_foco: bool):
	var projetil = projetil_cena.instantiate()
	projetil.position = position
	projetil.rotation = direcao.angle()
	projetil.dano = dano_base
	projetil.scale = Vector2(escala, escala)
	
	if projeteis_teleguiados:
		projetil.eh_teleguiado = true
	
	if projeteis_perfurantes and "perfurante" in projetil:
		projetil.perfurante = true

	if aplica_foco and tem_foco_penitente and foco_penitente_ativo:
		projetil.dano *= 3
		foco_penitente_ativo = false
		$FocoTimer.start()
		if hud: hud.atualizar_timer_foco(0.0)
		print("TIRO COM FOCO DISPARADO!")
		projetil.scale *= 1.2 

	get_parent().add_child(projetil)

func disparar_eco(direcao: Vector2):
	await get_tree().create_timer(0.1).timeout
	var dano_eco = max(1, int(dano_projetil * 0.5))
	criar_projetil(direcao, dano_eco, 0.7, false)

func sofrer_dano(quantidade):
	if invulneravel: return

	if chance_esquiva > 0.0:
		if randf() < chance_esquiva:
			print("ESQUIVA! Dano ignorado.")
			piscar_rapido()
			return

	var saude_projetada = saude_atual - quantidade
	
	if tem_baluarte_da_alma and not baluarte_usado_na_onda and saude_projetada <= 0:
		print("BALUARTE DA ALMA ATIVADO!")
		baluarte_usado_na_onda = true
		invulneravel = true
		$InvulnerabilidadeTimer.start()
		piscar()
		curar(2)
		return
	
	saude_atual = saude_projetada
	emit_signal("saude_alterada", saude_atual, saude_maxima)

	if damage_overlay_scene and damage_overlay_scene.has_method("play_damage_effect"):
		print("JOGADOR: Chamando overlay de dano na cena separada.")
		damage_overlay_scene.play_damage_effect()
	else:
		if hud and hud.has_method("mostrar_efeito_dano"):
			hud.mostrar_efeito_dano()
		else:
			print("JOGADOR AVISO: Nenhum efeito de dano visual encontrado (Nem cena, nem HUD).")

	if tem_guardiao_caido:
		ativar_onda_de_choque()
		
	if tem_foco_penitente:
		foco_penitente_ativo = false
		$FocoTimer.start()
		if hud: hud.atualizar_timer_foco(0.0)
		
	if saude_atual <= 0:
		print("JOGADOR MORREU!")
		emit_signal("morreu")
		queue_free()

func curar(quantidade):
	if not pode_curar:
		print("Maldição da Coroa do Mártir impede a cura!")
		return
	saude_atual = min(saude_atual + quantidade, saude_maxima)
	emit_signal("saude_alterada", saude_atual, saude_maxima)

func aumentar_vida_maxima(quantidade):
	saude_maxima += quantidade
	curar(quantidade)

func ativar_onda_de_choque():
	call_deferred("_spawn_onda_de_choque")

func _spawn_onda_de_choque():
	if not onda_de_choque_cena: return
	var onda = onda_de_choque_cena.instantiate()
	onda.global_position = global_position
	get_parent().add_child(onda)

func piscar():
	var tween = create_tween().set_loops(4)
	tween.tween_property(self, "modulate:a", 0.3, 0.25)
	tween.tween_property(self, "modulate:a", 1.0, 0.25)

func piscar_rapido():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.2, 0.1)
	tween.tween_property(self, "modulate:a", 1.0, 0.1)

func ativar_foco_penitente():
	tem_foco_penitente = true
	if hud:
		hud.mostrar_timer_foco(true)
		hud.atualizar_timer_foco(0.0)
	$FocoTimer.start()

func ativar_coroa_do_martir():
	projeteis_teleguiados = true
	pode_curar = false

func _on_timer_cadencia_timeout():
	pode_atirar = true

func _on_foco_timer_timeout():
	if tem_foco_penitente:
		foco_penitente_ativo = true
		if hud: hud.atualizar_timer_foco(1.0)

func _on_invulnerabilidade_timer_timeout():
	invulneravel = false
	modulate.a = 1.0
