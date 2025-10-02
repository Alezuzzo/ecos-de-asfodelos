# projetil.gd
extends Area2D

@export var velocidade = 800
@export var tempo_de_vida = 2.0

var dano = 1

func _ready():
	if has_node("TimerVida"):
		$TimerVida.wait_time = tempo_de_vida
		$TimerVida.start()

func _process(delta):
	position += transform.x * velocidade * delta

func _on_body_entered(body):
	if body.is_in_group("inimigos"):
		# Chama a função de dano do inimigo, passando o dano do projétil
		body.sofrer_dano(dano)
		
		# O projétil se destrói ao atingir um inimigo
		queue_free()

func _on_timer_vida_timeout():
	queue_free()
