# jogador.gd
extends CharacterBody2D

signal saude_alterada(saude_atual, saude_maxima)

#-----------------------------------------------------------------------------
# ATRIBUTOS DO JOGADOR
#-----------------------------------------------------------------------------
@export var velocidade = 300
@export var cadencia_tiro = 0.25
@export var dano_projetil = 1
@export var saude_maxima = 6
var saude_atual

#-----------------------------------------------------------------------------
# REFERÊNCIAS DE CENAS E NÓS
#-----------------------------------------------------------------------------
var projetil_cena = preload("res://projetil.tscn")
var onda_de_choque_cena = preload("res://onda_de_choque.tscn")
var hud = null

#-----------------------------------------------------------------------------
# ESTADO DAS MELHORIAS E CONTROLE
#-----------------------------------------------------------------------------
var pode_atirar = true
var cartas_coletadas = []
var tem_guardiao_caido = false
var tem_foco_penitente = false
var foco_penitente_ativo = false
var tem_baluarte_da_alma = false
var baluarte_usado_na_onda = false
var invulneravel = false

# --- NOVA VARIÁVEL PARA O ESTILO ISAAC ---
# Guarda a última direção em que o jogador atirou. Começa virado para a direita.
var ultima_direcao_tiro = Vector2.RIGHT

#-----------------------------------------------------------------------------
# FUNÇÕES DO GODOT
#-----------------------------------------------------------------------------

func _ready():
	saude_atual = saude_maxima
	emit_signal("saude_alterada", saude_atual, saude_maxima)

func _physics_process(delta):
	# Atualiza a barra de progresso visual, se ativa
	if tem_foco_penitente and not $FocoTimer.is_stopped():
		var progresso = 1.0 - ($FocoTimer.time_left / $FocoTimer.wait_time)
		if hud:
			hud.atualizar_timer_foco(progresso)

	# Lógica de Movimento e Tiro (permanece igual)
	handle_movimento()
	handle_tiro()
	handle_animacao()
	
	# --- LÓGICA DE LIMITAÇÃO DE TELA CORRIGIDA ---
	var tamanho_da_tela = get_viewport_rect().size
	# Pega a referência da forma de colisão
	var collision_shape = $CollisionShape2D.shape
	
	# Pega a "metade da largura" usando o raio da cápsula
	var metade_largura = collision_shape.radius
	# Pega a "metade da altura" usando a altura total da cápsula
	var metade_altura = collision_shape.height / 2.0
	
	# Usa os novos valores para limitar a posição
	global_position.x = clamp(global_position.x, metade_largura, tamanho_da_tela.x - metade_largura)
	global_position.y = clamp(global_position.y, metade_altura, tamanho_da_tela.y - metade_altura)
	# --- FIM DA CORREÇÃO ---
#-----------------------------------------------------------------------------
# NOVAS FUNÇÕES DE CONTROLE (ESTILO ISAAC)
#-----------------------------------------------------------------------------

func handle_movimento():
	var direcao = Input.get_vector("esquerda", "direita", "cima", "baixo")
	velocity = direcao * velocidade
	move_and_slide()

func handle_tiro():
	if not pode_atirar:
		return

	# Verifica as ações de tiro mapeadas para as setas do teclado
	if Input.is_action_pressed("shoot_up"):
		atirar(Vector2.UP)
	elif Input.is_action_pressed("shoot_down"):
		atirar(Vector2.DOWN)
	elif Input.is_action_pressed("shoot_left"):
		atirar(Vector2.LEFT)
	elif Input.is_action_pressed("shoot_right"):
		atirar(Vector2.RIGHT)

func handle_animacao():
	var sprite_animado = $AnimatedSprite2D
	
	# Animação baseada no MOVIMENTO (WASD)
	if velocity.length() > 0:
		if velocity.y > 0:
			sprite_animado.play("walk_down")
		elif velocity.y < 0:
			sprite_animado.play("walk_up")
		else: # Movimento apenas horizontal
			sprite_animado.play("walk_side")
	else:
		# Se PARADO, animação baseada na ÚLTIMA DIREÇÃO DE TIRO
		if ultima_direcao_tiro.y < 0:
			sprite_animado.play("walk_up") # Corpo virado para cima
		elif ultima_direcao_tiro.y > 0:
			sprite_animado.play("walk_down") # Corpo virado para baixo
		else:
			# Se o último tiro foi horizontal, usa a animação de lado/parado
			sprite_animado.play("idle") 

	# Lógica de virar o sprite (flip) baseada na ÚLTIMA DIREÇÃO DE TIRO
	if ultima_direcao_tiro.x < 0:
		sprite_animado.flip_h = true
	elif ultima_direcao_tiro.x > 0:
		sprite_animado.flip_h = false

#-----------------------------------------------------------------------------
# FUNÇÕES DE AÇÃO E EFEITOS (ATUALIZADAS)
#-----------------------------------------------------------------------------

func atirar(direcao_tiro: Vector2): # Agora recebe a direção do tiro
	pode_atirar = false
	ultima_direcao_tiro = direcao_tiro # ATUALIZA A "MEMÓRIA" DA MIRA
	
	var projetil = projetil_cena.instantiate()
	projetil.position = position
	
	# A rotação do projétil é baseada na direção do teclado
	projetil.rotation = direcao_tiro.angle()
	
	projetil.dano = dano_projetil
	if tem_foco_penitente and foco_penitente_ativo:
		projetil.dano *= 3
		foco_penitente_ativo = false
		$FocoTimer.start()
		if hud:
			hud.atualizar_timer_foco(0.0)
		print("TIRO COM FOCO DISPARADO!")
	
	get_parent().add_child(projetil)
	$TimerCadencia.start(cadencia_tiro)

func sofrer_dano(quantidade):
	if invulneravel: return

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
	
	if tem_guardiao_caido:
		ativar_onda_de_choque()
		
	if tem_foco_penitente:
		foco_penitente_ativo = false
		$FocoTimer.start()
		if hud:
			hud.atualizar_timer_foco(0.0)
		print("Foco do Penitente perdido! Reiniciando contagem.")
		
	if saude_atual <= 0:
		print("JOGADOR MORREU!")
		queue_free()

func piscar():
	var tween = create_tween().set_loops(4)
	tween.tween_property(self, "modulate:a", 0.3, 0.25)
	tween.tween_property(self, "modulate:a", 1.0, 0.25)

#-----------------------------------------------------------------------------
# FUNÇÕES CHAMADAS PELAS CARTAS
#-----------------------------------------------------------------------------

func ativar_foco_penitente():
	tem_foco_penitente = true
	if hud:
		hud.mostrar_timer_foco(true)
		hud.atualizar_timer_foco(0.0)
	$FocoTimer.start()

func ativar_onda_de_choque():
	var onda = onda_de_choque_cena.instantiate()
	onda.global_position = global_position
	get_parent().add_child(onda)

func aumentar_vida_maxima(quantidade):
	saude_maxima += quantidade
	curar(quantidade) 

func curar(quantidade):
	saude_atual = min(saude_atual + quantidade, saude_maxima)
	emit_signal("saude_alterada", saude_atual, saude_maxima)

#-----------------------------------------------------------------------------
# FUNÇÕES DE SINAIS (Callbacks)
#-----------------------------------------------------------------------------

func _on_timer_cadencia_timeout():
	pode_atirar = true

func _on_foco_timer_timeout():
	if tem_foco_penitente:
		foco_penitente_ativo = true
		if hud:
			hud.atualizar_timer_foco(1.0)
		print("Foco do Penitente ATIVADO!")

func _on_invulnerabilidade_timer_timeout():
	invulneravel = false
