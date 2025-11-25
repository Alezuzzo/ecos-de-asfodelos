# jogador.gd
extends CharacterBody2D

signal saude_alterada(saude_atual, saude_maxima)
signal morreu

#-----------------------------------------------------------------------------
# ATRIBUTOS DO JOGADOR
#-----------------------------------------------------------------------------
@export var velocidade = 300
@export var cadencia_tiro = 0.25
@export var dano_projetil = 1
@export var saude_maxima = 6
var saude_atual = 0

#-----------------------------------------------------------------------------
# REFERÊNCIAS DE CENAS E NÓS
#-----------------------------------------------------------------------------
var projetil_cena = preload("res://projetil.tscn")
var onda_de_choque_cena = preload("res://onda_de_choque.tscn")
var hud = null
@onready var shot_sound_player = $ShotSoundPlayer
@onready var sprite_animado = $AnimatedSprite2D # Cache da referência

#-----------------------------------------------------------------------------
# ESTADO DAS MELHORIAS E CONTROLE
#-----------------------------------------------------------------------------
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
var chance_esquiva = 0.0 # Ex: 0.1 = 10%
var tem_ecos_desafiante = false

# Cartas Corrompidas
var pode_curar = true
var projeteis_teleguiados = false


#-----------------------------------------------------------------------------
# FUNÇÕES DO GODOT
#-----------------------------------------------------------------------------

func _ready():
	saude_atual = saude_maxima
	emit_signal("saude_alterada", saude_atual, saude_maxima)

func _physics_process(delta):
	# Atualiza o timer visual do Foco do Penitente
	if tem_foco_penitente and not $FocoTimer.is_stopped():
		var progresso = 1.0 - ($FocoTimer.time_left / $FocoTimer.wait_time)
		if hud: hud.atualizar_timer_foco(progresso)

	# Verifica inputs de tiro
	esta_atirando_agora = Input.is_action_pressed("shoot_up") or \
						  Input.is_action_pressed("shoot_down") or \
						  Input.is_action_pressed("shoot_left") or \
						  Input.is_action_pressed("shoot_right")

	handle_movimento()
	handle_tiro()
	handle_animacao()
	clamp_position_to_screen()

#-----------------------------------------------------------------------------
# CONTROLE DE MOVIMENTO E ANIMAÇÃO
#-----------------------------------------------------------------------------

func handle_movimento():
	var direcao = Input.get_vector("esquerda", "direita", "cima", "baixo")
	velocity = direcao * velocidade
	move_and_slide()

func handle_tiro():
	if not pode_atirar: return
	if Input.is_action_pressed("shoot_up"): atirar(Vector2.UP)
	elif Input.is_action_pressed("shoot_down"): atirar(Vector2.DOWN)
	elif Input.is_action_pressed("shoot_left"): atirar(Vector2.LEFT)
	elif Input.is_action_pressed("shoot_right"): atirar(Vector2.RIGHT)

func handle_animacao():
	# 1. Define a animação baseada no movimento (WASD)
	if velocity.length() > 0:
		if velocity.y > 0: sprite_animado.play("walk_down")
		elif velocity.y < 0: sprite_animado.play("walk_up")
		else: sprite_animado.play("walk_side")
	else:
		# Se parado, define a postura baseada na última direção de tiro
		# (Isso mantém o personagem "mirando" mesmo parado)
		if ultima_direcao_tiro.y < 0: sprite_animado.play("walk_up")
		elif ultima_direcao_tiro.y > 0: sprite_animado.play("walk_down")
		else: sprite_animado.play("idle")
	
	# 2. Define o espelhamento (Flip H)
	# Se estiver atirando, a prioridade é a direção do tiro
	if esta_atirando_agora:
		if ultima_direcao_tiro.x < 0: sprite_animado.flip_h = true
		elif ultima_direcao_tiro.x > 0: sprite_animado.flip_h = false
	# Se não estiver atirando mas estiver andando, olha pra onde anda
	elif velocity.x != 0:
		if velocity.x < 0: sprite_animado.flip_h = true
		elif velocity.x > 0: sprite_animado.flip_h = false
	# Se parado e não atirando, mantém o último flip.

func clamp_position_to_screen():
	var tamanho_da_tela = get_viewport_rect().size
	var collision_shape_node = $CollisionShape2D
	if is_instance_valid(collision_shape_node) and is_instance_valid(collision_shape_node.shape):
		var shape = collision_shape_node.shape
		var metade_largura = shape.radius if shape is CapsuleShape2D else shape.size.x / 2.0
		var metade_altura = shape.height / 2.0 if shape is CapsuleShape2D else shape.size.y / 2.0
		global_position.x = clamp(global_position.x, metade_largura, tamanho_da_tela.x - metade_largura)
		global_position.y = clamp(global_position.y, metade_altura, tamanho_da_tela.y - metade_altura)

#-----------------------------------------------------------------------------
# SISTEMA DE TIRO E PROJÉTEIS
#-----------------------------------------------------------------------------

func atirar(direcao_tiro: Vector2):
	if shot_sound_player: shot_sound_player.play()
	pode_atirar = false
	ultima_direcao_tiro = direcao_tiro
	
	# Cria o projétil principal (Dano total, Tamanho normal)
	criar_projetil(direcao_tiro, dano_projetil, 1.0, true)
	
	# Se tiver a Sinergia "Ecos do Desafiante", dispara o eco
	if tem_ecos_desafiante:
		disparar_eco(direcao_tiro)

	$TimerCadencia.start(cadencia_tiro)

# Função auxiliar para evitar repetição de código na criação de projéteis
func criar_projetil(direcao: Vector2, dano_base: int, escala: float, aplica_foco: bool):
	var projetil = projetil_cena.instantiate()
	projetil.position = position
	projetil.rotation = direcao.angle()
	projetil.dano = dano_base
	projetil.scale = Vector2(escala, escala)
	
	# Aplica carta "Coroa do Mártir"
	if projeteis_teleguiados:
		projetil.eh_teleguiado = true
	
	# Aplica carta "Lágrimas Perfurantes"
	if projeteis_perfurantes and "perfurante" in projetil:
		projetil.perfurante = true

	# Aplica carta "Foco do Penitente" (apenas no tiro principal)
	if aplica_foco and tem_foco_penitente and foco_penitente_ativo:
		projetil.dano *= 3
		foco_penitente_ativo = false
		$FocoTimer.start()
		if hud: hud.atualizar_timer_foco(0.0)
		print("TIRO COM FOCO DISPARADO!")
		# Opcional: Aumentar visualmente o tiro crítico
		projetil.scale *= 1.2 

	get_parent().add_child(projetil)

# Função assíncrona para o tiro secundário (Eco)
func disparar_eco(direcao: Vector2):
	await get_tree().create_timer(0.1).timeout # Pequeno atraso
	# Eco causa 50% do dano e é menor
	var dano_eco = max(1, int(dano_projetil * 0.5))
	# Cria o eco (sem aplicar o bônus de foco novamente)
	criar_projetil(direcao, dano_eco, 0.7, false)

#-----------------------------------------------------------------------------
# SISTEMA DE DANO E CURA
#-----------------------------------------------------------------------------

func sofrer_dano(quantidade):
	if invulneravel: return

	# Carta "Forma Fantasma": Chance de esquiva
	if chance_esquiva > 0.0:
		if randf() < chance_esquiva:
			print("ESQUIVA! Dano ignorado.")
			piscar_rapido()
			return

	var saude_projetada = saude_atual - quantidade
	
	# Sinergia "Baluarte da Alma": Previne morte uma vez por onda
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
	
	# Carta "Guardião Caído": Onda de choque ao receber dano
	if tem_guardiao_caido:
		ativar_onda_de_choque()
		
	# Carta "Foco do Penitente": Reseta se tomar dano
	if tem_foco_penitente:
		foco_penitente_ativo = false
		$FocoTimer.start()
		if hud: hud.atualizar_timer_foco(0.0)
		print("Foco do Penitente perdido! Reiniciando contagem.")
		
	if saude_atual <= 0:
		print("JOGADOR MORREU!")
		emit_signal("morreu")
		queue_free()

func curar(quantidade):
	# Carta Corrompida: Impede cura
	if not pode_curar:
		print("Maldição da Coroa do Mártir impede a cura!")
		return
	saude_atual = min(saude_atual + quantidade, saude_maxima)
	emit_signal("saude_alterada", saude_atual, saude_maxima)

func aumentar_vida_maxima(quantidade):
	saude_maxima += quantidade
	curar(quantidade)

#-----------------------------------------------------------------------------
# EFEITOS VISUAIS E ATIVAÇÕES
#-----------------------------------------------------------------------------

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

func piscar_rapido(): # Para a esquiva
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.2, 0.1)
	tween.tween_property(self, "modulate:a", 1.0, 0.1)

#-----------------------------------------------------------------------------
# ATIVAÇÃO DE CARTAS (Chamadas pela Arena)
#-----------------------------------------------------------------------------

func ativar_foco_penitente():
	tem_foco_penitente = true
	if hud:
		hud.mostrar_timer_foco(true)
		hud.atualizar_timer_foco(0.0)
	$FocoTimer.start()

func ativar_coroa_do_martir():
	projeteis_teleguiados = true
	pode_curar = false

#-----------------------------------------------------------------------------
# SIGNALS (CALLBACKS)
#-----------------------------------------------------------------------------

func _on_timer_cadencia_timeout():
	pode_atirar = true

func _on_foco_timer_timeout():
	if tem_foco_penitente:
		foco_penitente_ativo = true
		if hud: hud.atualizar_timer_foco(1.0)

func _on_invulnerabilidade_timer_timeout():
	invulneravel = false
	modulate.a = 1.0
