extends Area2D

@export var velocidade = 800
@export var tempo_de_vida = 3.0
@export var velocidade_de_curva = 4.0

var dano = 1

var eh_teleguiado = false
var alvo: Node2D = null

func _ready():
	$TimerVida.start(tempo_de_vida)

func _process(delta):
	if eh_teleguiado:
		if not is_instance_valid(alvo):
			alvo = encontrar_alvo_mais_proximo()
		
		if is_instance_valid(alvo):
			var direcao_para_alvo = global_position.direction_to(alvo.global_position)
			var direcao_atual = Vector2.RIGHT.rotated(rotation)
			
			var nova_direcao = direcao_atual.slerp(direcao_para_alvo, velocidade_de_curva * delta)
			rotation = nova_direcao.angle()
	
	position += transform.x * velocidade * delta

# Função para encontrar o inimigo mais próximo na tela.
func encontrar_alvo_mais_proximo():
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	var alvo_proximo = null
	# Usa a distância do quadrado para performance, mais rápido de calcular
	var distancia_minima_sq = INF
	
	for inimigo in inimigos:
		var distancia_sq = global_position.distance_squared_to(inimigo.global_position)
		if distancia_sq < distancia_minima_sq:
			distancia_minima_sq = distancia_sq
			alvo_proximo = inimigo
			
	return alvo_proximo

# Função chamada quando o projétil colide com um corpo.
func _on_body_entered(body):
	# Se colidimos com algo do grupo "inimigos"
	if body.is_in_group("inimigos"):
		# Se o inimigo tiver o método "sofrer_dano"
		if body.has_method("sofrer_dano"):
			body.sofrer_dano(dano)
		# O projétil se destrói ao atingir um alvo
		queue_free()

func _on_timer_vida_timeout():
	queue_free()
