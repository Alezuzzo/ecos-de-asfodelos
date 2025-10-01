# jogador.gd
extends CharacterBody2D

# Atributos do jogador
@export var velocidade = 300
@export var cadencia_tiro = 0.25 # Tiros por segundo
var pode_atirar = true

# Pre-carrega a cena do projétil que vamos criar no próximo passo
var projetil_cena = preload("res://projetil.tscn")

func _physics_process(delta):
	# Movimentação
	var direcao = Input.get_vector("esquerda", "direita", "cima", "baixo")
	velocity = direcao * velocidade
	move_and_slide()

	# Rotação para olhar na direção do mouse
	look_at(get_global_mouse_position())

	# Tiro
	if Input.is_action_pressed("atirar") and pode_atirar:
		atirar()

func atirar():
	pode_atirar = false
	
	# Cria uma instância do projétil
	var projetil = projetil_cena.instantiate()
	projetil.position = position
	projetil.rotation = rotation
	
	# Adiciona o projétil à cena principal (fora do jogador)
	get_parent().add_child(projetil)
	
	# Inicia o timer para a cadência de tiro
	$TimerCadencia.start(cadencia_tiro)


func _on_timer_cadencia_timeout():
	pode_atirar = true
