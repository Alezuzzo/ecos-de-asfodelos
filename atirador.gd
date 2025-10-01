# atirador.gd
extends CharacterBody2D

signal morreu

@export var velocidade = 100
@export var distancia_ideal = 300 # Distância que ele tenta manter do jogador
@export var cadencia_tiro = 1.5 # 1 tiro a cada 1.5 segundos

var jogador = null
var pode_atirar = true
var projetil_inimigo_cena = preload("res://projetil_inimigo.tscn")

func _physics_process(delta):
	if jogador:
		var direcao_para_jogador = global_position.direction_to(jogador.global_position)
		var distancia = global_position.distance_to(jogador.global_position)
		
		# Lógica de movimento
		if distancia > distancia_ideal + 20: # Se estiver muito longe, aproxima-se
			velocity = direcao_para_jogador * velocidade
		elif distancia < distancia_ideal - 20: # Se estiver muito perto, afasta-se
			velocity = -direcao_para_jogador * velocidade
		else: # Se estiver na distância ideal, para de se mover e atira
			velocity = Vector2.ZERO
			if pode_atirar:
				atirar()
		
		move_and_slide()

func atirar():
	pode_atirar = false
	
	var projetil = projetil_inimigo_cena.instantiate()
	projetil.position = position
	# Faz o projétil olhar na direção do jogador
	projetil.look_at(jogador.global_position)
	
	get_parent().add_child(projetil)
	
	# Usa um Timer para controlar a cadência
	$TiroTimer.start(cadencia_tiro)

func _on_tiro_timer_timeout():
	pode_atirar = true
