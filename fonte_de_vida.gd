extends Area2D

@export var tempo_de_vida = 8.0 # Segundos que a fonte fica ativa
@export var quantidade_cura = 1

func _ready():
	$VidaTimer.start(tempo_de_vida)

func _on_body_entered(body):
	if body.is_in_group("jogador"):
		# Chama a função "curar" no jogador
		body.curar(quantidade_cura)
		print("JOGADOR CUROU!")
		queue_free() # Destrói a fonte após o uso

func _on_vida_timer_timeout():
	# Destrói a fonte se o tempo acabar
	queue_free()
