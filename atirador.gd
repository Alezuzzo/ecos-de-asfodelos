# atirador.gd
extends CharacterBody2D

signal morreu

@export var velocidade = 100
@export var distancia_ideal = 300
@export var cadencia_tiro = 1.5
@export var vida = 2 # <-- VIDA ADICIONADA AQUI (ex: um atirador pode ter menos vida)

var jogador = null
var pode_atirar = true
var projetil_inimigo_cena = preload("res://projetil_inimigo.tscn")

func sofrer_dano(dano):
	vida -= dano
	hit_flash()
	if vida <= 0:
		emit_signal("morreu")
		queue_free()

func hit_flash():
	var tween = create_tween()
	tween.tween_property($ColorRect, "modulate", Color.WHITE, 0.1)
	tween.tween_property($ColorRect, "modulate", Color(1,1,1,1), 0.1)

# ... (o resto do script do atirador continua igual) ...

func _physics_process(delta):
	if jogador:
		var direcao_para_jogador = global_position.direction_to(jogador.global_position)
		var distancia = global_position.distance_to(jogador.global_position)
		
		if distancia > distancia_ideal + 20:
			velocity = direcao_para_jogador * velocidade
		elif distancia < distancia_ideal - 20:
			velocity = -direcao_para_jogador * velocidade
		else:
			velocity = Vector2.ZERO
			if pode_atirar:
				atirar()
		move_and_slide()

func atirar():
	pode_atirar = false
	var projetil = projetil_inimigo_cena.instantiate()
	projetil.position = position
	projetil.look_at(jogador.global_position)
	get_parent().add_child(projetil)
	$TiroTimer.start(cadencia_tiro)

func _on_tiro_timer_timeout():
	pode_atirar = true
