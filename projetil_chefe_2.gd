extends Area2D

@export var velocidade = 500 
@export var tempo_de_vida = 3.0
@export var dano = 1

func _ready():
	var timer = get_node_or_null("TimerVida")
	if is_instance_valid(timer):
		timer.start(tempo_de_vida)
	else:
		printerr("ERRO em projetil_chefe_2: Nó TimerVida não encontrado!")

func _process(delta):
	position += transform.x * velocidade * delta

func _on_body_entered(body):
	if body.is_in_group("jogador"):
		if body.has_method("sofrer_dano"):
			var dano_causado = dano if "dano" in self else 1
			body.sofrer_dano(dano_causado)
		queue_free()

func _on_timer_vida_timeout():
	queue_free()
