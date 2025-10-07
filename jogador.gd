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
# ESTADO DAS MELHORIAS (FLAGS)
#-----------------------------------------------------------------------------
var pode_atirar = true

# Afinidade da Resiliência
var cartas_coletadas = []
var tem_guardiao_caido = false
var tem_foco_penitente = false
var foco_penitente_ativo = false
var tem_baluarte_da_alma = false
var baluarte_usado_na_onda = false
var invulneravel = false

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

	# Lógica de Movimento
	var direcao = Input.get_vector("esquerda", "direita", "cima", "baixo")
	velocity = direcao * velocidade
	move_and_slide()
	
	# Pega a referência do sprite uma vez
	var sprite_animado = $AnimatedSprite2D
	
	# --- LÓGICA DE ANIMAÇÃO FINAL E COMPLETA ---
	if velocity.length() > 0: # Se o jogador está se movendo
		# Prioriza as animações verticais
		if direcao.y > 0:
			sprite_animado.play("walk_down")
		elif direcao.y < 0:
			# --- CORREÇÃO AQUI: Toca a nova animação de andar para cima ---
			sprite_animado.play("walk_up") 
		else:
			# Se não há movimento vertical, toca a animação lateral
			sprite_animado.play("walk_side")
	else: # Se o jogador está parado
		sprite_animado.play("idle")
	
	# Lógica de virar o sprite (flip) baseado na posição do mouse
	var posicao_do_mouse = get_global_mouse_position()
	if posicao_do_mouse.x < global_position.x:
		sprite_animado.flip_h = true
	else:
		sprite_animado.flip_h = false
	
	# Lógica de limitação da tela
	var tamanho_da_tela = get_viewport_rect().size
	var metade_do_tamanho_sprite = $CollisionShape2D.shape.size / 2.0
	global_position.x = clamp(global_position.x, metade_do_tamanho_sprite.x, tamanho_da_tela.x - metade_do_tamanho_sprite.x)
	global_position.y = clamp(global_position.y, metade_do_tamanho_sprite.y, tamanho_da_tela.y - metade_do_tamanho_sprite.y)

	# Lógica de tiro
	if Input.is_action_pressed("atirar") and pode_atirar:
		atirar()

#-----------------------------------------------------------------------------
# FUNÇÕES DE AÇÃO E EFEITOS
#-----------------------------------------------------------------------------

func atirar():
	pode_atirar = false
	var projetil = projetil_cena.instantiate()
	projetil.position = position
	projetil.rotation = global_position.direction_to(get_global_mouse_position()).angle()
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
