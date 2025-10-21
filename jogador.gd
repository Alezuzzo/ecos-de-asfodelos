# jogador.gd
extends CharacterBody2D

signal saude_alterada(saude_atual, saude_maxima)
signal morreu # Sinal para avisar a Arena quando o jogador morre

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
var ultima_direcao_tiro = Vector2.RIGHT
var pode_curar = true
var projeteis_teleguiados = false
var esta_atirando_agora = false

#-----------------------------------------------------------------------------
# FUNÇÕES DO GODOT
#-----------------------------------------------------------------------------

func _ready():
	saude_atual = saude_maxima
	emit_signal("saude_alterada", saude_atual, saude_maxima)

func _physics_process(delta):
	if tem_foco_penitente and not $FocoTimer.is_stopped():
		var progresso = 1.0 - ($FocoTimer.time_left / $FocoTimer.wait_time)
		if hud:
			hud.atualizar_timer_foco(progresso)

	esta_atirando_agora = Input.is_action_pressed("shoot_up") or \
						  Input.is_action_pressed("shoot_down") or \
						  Input.is_action_pressed("shoot_left") or \
						  Input.is_action_pressed("shoot_right")

	handle_movimento()
	handle_tiro()
	handle_animacao()
	clamp_position_to_screen() # Chama a função de limitação de tela

#-----------------------------------------------------------------------------
# FUNÇÕES DE CONTROLE (ESTILO ISAAC HÍBRIDO)
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
	var sprite_animado = $AnimatedSprite2D
	if velocity.length() > 0:
		if velocity.y > 0: sprite_animado.play("walk_down")
		elif velocity.y < 0: sprite_animado.play("walk_up")
		else: sprite_animado.play("walk_side")
	else:
		sprite_animado.play("idle")
	if esta_atirando_agora:
		if ultima_direcao_tiro.x < 0: sprite_animado.flip_h = true
		elif ultima_direcao_tiro.x > 0: sprite_animado.flip_h = false
	elif velocity.x != 0:
		if velocity.x < 0: sprite_animado.flip_h = true
		elif velocity.x > 0: sprite_animado.flip_h = false
	if velocity.length() == 0:
		if ultima_direcao_tiro.y < 0: sprite_animado.play("walk_up")
		elif ultima_direcao_tiro.y > 0: sprite_animado.play("walk_down")

func clamp_position_to_screen(): # Função para limitar à tela
	var tamanho_da_tela = get_viewport_rect().size
	# Verifica se o CollisionShape2D e seu shape existem antes de acessá-los
	var collision_shape_node = $CollisionShape2D
	if is_instance_valid(collision_shape_node) and is_instance_valid(collision_shape_node.shape):
		var shape = collision_shape_node.shape
		var metade_largura = shape.radius if shape is CapsuleShape2D else shape.size.x / 2.0
		var metade_altura = shape.height / 2.0 if shape is CapsuleShape2D else shape.size.y / 2.0
		global_position.x = clamp(global_position.x, metade_largura, tamanho_da_tela.x - metade_largura)
		global_position.y = clamp(global_position.y, metade_altura, tamanho_da_tela.y - metade_altura)
	else:
		# Fallback seguro se a colisão não estiver pronta (raro, mas evita crash)
		global_position.x = clamp(global_position.x, 0, tamanho_da_tela.x)
		global_position.y = clamp(global_position.y, 0, tamanho_da_tela.y)


#-----------------------------------------------------------------------------
# FUNÇÕES DE AÇÃO E EFEITOS
#-----------------------------------------------------------------------------

func atirar(direcao_tiro: Vector2):
	pode_atirar = false
	ultima_direcao_tiro = direcao_tiro
	var projetil = projetil_cena.instantiate()
	projetil.position = position
	projetil.rotation = direcao_tiro.angle()
	projetil.dano = dano_projetil
	if projeteis_teleguiados:
		projetil.eh_teleguiado = true
	if tem_foco_penitente and foco_penitente_ativo:
		projetil.dano *= 3
		foco_penitente_ativo = false
		$FocoTimer.start()
		if hud: hud.atualizar_timer_foco(0.0)
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
		ativar_onda_de_choque() # Chama a função que agora usa call_deferred
	if tem_foco_penitente:
		foco_penitente_ativo = false
		$FocoTimer.start()
		if hud: hud.atualizar_timer_foco(0.0)
		print("Foco do Penitente perdido! Reiniciando contagem.")
	if saude_atual <= 0:
		print("JOGADOR MORREU!")
		emit_signal("morreu")
		queue_free()

func piscar():
	var tween = create_tween().set_loops(4)
	tween.tween_property(self, "modulate:a", 0.3, 0.25)
	tween.tween_property(self, "modulate:a", 1.0, 0.25)

#-----------------------------------------------------------------------------
# FUNÇÕES CHAMADAS PELAS CARTAS
#-----------------------------------------------------------------------------

func aumentar_vida_maxima(quantidade):
	saude_maxima += quantidade
	curar(quantidade)

func curar(quantidade):
	if not pode_curar:
		print("Maldição da Coroa do Mártir impede a cura!")
		return
	saude_atual = min(saude_atual + quantidade, saude_maxima)
	emit_signal("saude_alterada", saude_atual, saude_maxima)

# --- FUNÇÃO ATIVAR ONDA DE CHOQUE CORRIGIDA ---
func ativar_onda_de_choque():
	# Adia a criação da onda para um momento seguro (idle time)
	call_deferred("_spawn_onda_de_choque")

# Nova função auxiliar que faz o trabalho real de criar a onda
func _spawn_onda_de_choque():
	if not onda_de_choque_cena:
		print("ERRO em Jogador: Cena da Onda de Choque não está carregada.")
		return
	var onda = onda_de_choque_cena.instantiate()
	onda.global_position = global_position
	# Adiciona a onda como irmã do jogador (geralmente no YSortContainer)
	get_parent().add_child(onda)
# --- FIM DA CORREÇÃO ---

func ativar_foco_penitente():
	tem_foco_penitente = true
	if hud:
		hud.mostrar_timer_foco(true)
		hud.atualizar_timer_foco(0.0)
	$FocoTimer.start()

func ativar_coroa_do_martir():
	print("CARTA CORROMPIDA ATIVADA: Coroa do Mártir!")
	projeteis_teleguiados = true
	pode_curar = false

#-----------------------------------------------------------------------------
# FUNÇÕES DE SINAIS (Callbacks)
#-----------------------------------------------------------------------------

func _on_timer_cadencia_timeout():
	pode_atirar = true

func _on_foco_timer_timeout():
	if tem_foco_penitente:
		foco_penitente_ativo = true
		if hud: hud.atualizar_timer_foco(1.0)
		print("Foco do Penitente ATIVADO!")

func _on_invulnerabilidade_timer_timeout():
	invulneravel = false
	modulate.a = 1.0 # Garante que volta à opacidade total
