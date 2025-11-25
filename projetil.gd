extends Area2D

@export var velocidade = 800
@export var tempo_de_vida = 3.0
@export var velocidade_de_curva = 4.0

var dano = 1


var eh_teleguiado = false
var alvo: Node2D = null


var perfurante = false 
var inimigos_atingidos = [] 

func _ready():
	if has_node("TimerVida"):
		$TimerVida.start(tempo_de_vida)
	else:
		get_tree().create_timer(tempo_de_vida).timeout.connect(queue_free)

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


func encontrar_alvo_mais_proximo():
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	var alvo_proximo = null
	var distancia_minima_sq = INF
	
	for inimigo in inimigos:

		if perfurante and inimigo in inimigos_atingidos:
			continue
		
		var distancia_sq = global_position.distance_squared_to(inimigo.global_position)
		if distancia_sq < distancia_minima_sq:
			distancia_minima_sq = distancia_sq
			alvo_proximo = inimigo
			
	return alvo_proximo


func _on_body_entered(body):
	if body.is_in_group("inimigos"):

		if perfurante:
			if body in inimigos_atingidos:
				return 
			else:
				inimigos_atingidos.append(body) 

		if body.has_method("sofrer_dano"):
			body.sofrer_dano(dano)
		
		if not perfurante:
			queue_free()

func _on_timer_vida_timeout():
	queue_free()
