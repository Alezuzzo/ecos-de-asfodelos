# projetil.gd
extends Area2D

@export var velocidade = 800
@export var tempo_de_vida = 2.0 # É uma boa prática usar .0 para segundos

# Esta variável receberá o valor de dano do jogador quando o projétil for criado.
var dano = 1

func _ready():
	# Inicia um timer para se autodestruir depois de um tempo
	# É bom garantir que o timer exista antes de usá-lo
	if has_node("TimerVida"):
		$TimerVida.wait_time = tempo_de_vida
		$TimerVida.start()

func _process(delta):
	# Move o projétil para frente (usando o vetor 'forward' local)
	position += transform.x * velocidade * delta

func _on_body_entered(body):
	# Verifica se o corpo que entrou na área do projétil pertence ao grupo "inimigos"
	if body.is_in_group("inimigos"):
		# Emite o sinal para que a Arena saiba que o inimigo morreu
		body.emit_signal("morreu")
		
		# No futuro, em vez de destruir o inimigo, você faria algo como:
		# body.receber_dano(dano)
		
		# Por enquanto, continuamos destruindo o inimigo e o projétil
		body.queue_free()
		queue_free()

func _on_timer_vida_timeout():
	# Destrói o projétil quando o tempo de vida acaba para não poluir a cena
	queue_free()
