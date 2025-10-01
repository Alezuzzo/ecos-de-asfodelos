# jogador.gd
extends CharacterBody2D

signal saude_alterada(saude_atual, saude_maxima)

# Atributos de Combate
@export var velocidade = 300
@export var cadencia_tiro = 0.25
@export var dano_projetil = 1
var pode_atirar = true

# Atributos de Vida
@export var saude_maxima = 6 # 3 corações = 6 pontos
var saude_atual

# Cenas
var projetil_cena = preload("res://projetil.tscn")

# --- NOVAS VARIÁVEIS AQUI ---
var tamanho_da_tela: Vector2
var metade_do_tamanho_sprite = Vector2(16, 16) # Metade do tamanho do nosso sprite (32x32)

func _ready():
	saude_atual = saude_maxima
	emit_signal("saude_alterada", saude_atual, saude_maxima)
	
	# --- ADIÇÃO AQUI ---
	# Pega o tamanho da tela uma vez no início e o guarda na variável.
	tamanho_da_tela = get_viewport_rect().size

func _physics_process(delta):
	# Movimentação
	var direcao = Input.get_vector("esquerda", "direita", "cima", "baixo")
	velocity = direcao * velocidade
	move_and_slide()

	# Rotação para olhar na direção do mouse
	look_at(get_global_mouse_position())
	
	# --- LÓGICA DE LIMITAÇÃO DA TELA AQUI ---
	# A função clamp() força um valor a ficar entre um mínimo e um máximo.
	# Usamos a posição global para garantir precisão.
	global_position.x = clamp(global_position.x, metade_do_tamanho_sprite.x, tamanho_da_tela.x - metade_do_tamanho_sprite.x)
	global_position.y = clamp(global_position.y, metade_do_tamanho_sprite.y, tamanho_da_tela.y - metade_do_tamanho_sprite.y)
	# --- FIM DA LÓGICA DE LIMITAÇÃO ---

	# Tiro
	if Input.is_action_pressed("atirar") and pode_atirar:
		atirar()

# ... (O resto do seu script continua aqui, sem nenhuma outra alteração) ...

func atirar():
	pode_atirar = false
	
	var projetil = projetil_cena.instantiate()
	projetil.position = position
	projetil.rotation = rotation
	
	projetil.dano = dano_projetil 
	
	get_parent().add_child(projetil)
	
	$TimerCadencia.start(cadencia_tiro)

func _on_timer_cadencia_timeout():
	pode_atirar = true

func sofrer_dano(quantidade):
	saude_atual -= quantidade
	emit_signal("saude_alterada", saude_atual, saude_maxima)
	
	if saude_atual <= 0:
		queue_free()

func curar(quantidade):
	saude_atual = min(saude_atual + quantidade, saude_maxima)
	emit_signal("saude_alterada", saude_atual, saude_maxima)
