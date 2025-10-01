# projetil_inimigo.gd
extends Area2D

@export var velocidade = 400
@export var tempo_de_vida = 3.0

func _ready():
	$TimerVida.start(tempo_de_vida)

func _process(delta):
	position += transform.x * velocidade * delta

# Esta é a parte importante: a colisão com o jogador
func _on_body_entered(body):
	# Se atingir um corpo que está no grupo "jogador"
	if body.is_in_group("jogador"):
		# No futuro, aqui você diminuiria a vida do jogador.
		# Por enquanto, vamos apenas destruir o jogador para testar.
		print("JOGADOR ATINGIDO!")
		body.queue_free() # Destrói o jogador
		queue_free() # Destrói o projétil

func _on_timer_vida_timeout():
	queue_free()
