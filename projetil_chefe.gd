extends Area2D

@export var velocidade = 400
@export var tempo_de_vida = 3.0

func _ready():
	$TimerVida.start(tempo_de_vida)

func _process(delta):
	position += transform.x * velocidade * delta

#a colisão com o jogador
func _on_body_entered(body):
	if body.is_in_group("jogador"):
		body.sofrer_dano(1) # Causa 1 de dano (meio coração)
		queue_free() # Destrói o projétil

func _on_timer_vida_timeout():
	queue_free()
