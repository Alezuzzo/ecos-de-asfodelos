# jogador.gd
extends CharacterBody2D

signal saude_alterada(saude_atual, saude_maxima)

# Atributos
@export var velocidade = 300
@export var cadencia_tiro = 0.25
@export var dano_projetil = 1
@export var saude_maxima = 6
var saude_atual

# Referências
var projetil_cena = preload("res://projetil.tscn")
var onda_de_choque_cena = preload("res://onda_de_choque.tscn")
var hud = null # Guardará a referência do HUD

# Estado das Melhorias
var pode_atirar = true
var tem_guardiao_caido = false
var tem_foco_penitente = false
var foco_penitente_ativo = false

func _ready():
	saude_atual = saude_maxima
	emit_signal("saude_alterada", saude_atual, saude_maxima)

func _physics_process(delta):
	# Atualiza a barra de progresso visual a cada frame
	if tem_foco_penitente and not $FocoTimer.is_stopped():
		var progresso = 1.0 - ($FocoTimer.time_left / $FocoTimer.wait_time)
		if hud:
			hud.atualizar_timer_foco(progresso)

	# Movimentação e outras lógicas
	var direcao = Input.get_vector("esquerda", "direita", "cima", "baixo")
	velocity = direcao * velocidade
	move_and_slide()
	look_at(get_global_mouse_position())
	
	global_position.x = clamp(global_position.x, 16, get_viewport_rect().size.x - 16)
	global_position.y = clamp(global_position.y, 16, get_viewport_rect().size.y - 16)

	if Input.is_action_pressed("atirar") and pode_atirar:
		atirar()

func atirar():
	pode_atirar = false
	var projetil = projetil_cena.instantiate()
	projetil.position = position
	projetil.rotation = rotation
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
	saude_atual -= quantidade
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
		queue_free()

# --- NOVAS E ANTIGAS FUNÇÕES DE MELHORIA ---
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

# --- FUNÇÕES DE SINAIS (Callbacks) ---
func _on_timer_cadencia_timeout():
	pode_atirar = true

func _on_foco_timer_timeout():
	if tem_foco_penitente:
		foco_penitente_ativo = true
		if hud:
			hud.atualizar_timer_foco(1.0)
		print("Foco do Penitente ATIVADO!")
