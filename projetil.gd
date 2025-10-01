# projetil.gd
extends Area2D

@export var velocidade = 800
@export var tempo_de_vida = 2 # Segundos

func _ready():
	# Inicia um timer para se autodestruir depois de um tempo
	$TimerVida.wait_time = tempo_de_vida
	$TimerVida.start()

func _process(delta):
	# Move o projétil para frente
	position += transform.x * velocidade * delta

func _on_body_entered(body):
	# Se o projétil atingir um inimigo
	if body.is_in_group("inimigos"):
		body.queue_free() # Destrói o inimigo
		queue_free() # Destrói o projétil

func _on_timer_vida_timeout():
	queue_free() # Destrói o projétil quando o tempo de vida acaba
