# inimigo.gd
extends CharacterBody2D

signal morreu

@export var velocidade = 150
var jogador = null

func _physics_process(delta):
	# Se o jogador existir, calcula a direção e se move até ele
	if jogador:
		var direcao = global_position.direction_to(jogador.global_position)
		velocity = direcao * velocidade
	else:
		velocity = Vector2.ZERO # Fica parado se não encontrar o jogador
		
	move_and_slide()
