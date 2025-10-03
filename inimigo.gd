# inimigo.gd
extends CharacterBody2D

signal morreu

@export var velocidade = 150
@export var vida = 3
@export var dano_por_toque = 1

var jogador = null
var pode_causar_dano = true
var atordoado = false

# --- NOVA FUNÇÃO DE REPULSÃO ---
func aplicar_repulsao(direcao, forca):
	# Se já estiver atordoado, não aplica de novo
	if atordoado: return
	
	print(self.name, "foi repelido!") # DEBUG
	atordoado = true
	# move_and_collide é mais direto para um empurrão único
	move_and_collide(direcao * forca * get_physics_process_delta_time())
	$StunTimer.start(0.3)

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

func _physics_process(delta):
	# --- LÓGICA DE ATORDOAMENTO REVISADA ---
	# Se estiver atordoado, a única coisa que o inimigo faz é parar.
	if atordoado:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	# ----------------------------------------
	
	if jogador:
		var direcao = global_position.direction_to(jogador.global_position)
		velocity = direcao * velocidade
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()
	
	for i in range(get_slide_collision_count()):
		var colisao = get_slide_collision(i)
		if colisao.get_collider().is_in_group("jogador"):
			if pode_causar_dano:
				colisao.get_collider().sofrer_dano(dano_por_toque)
				pode_causar_dano = false
				$DanoCooldown.start()

func _on_dano_cooldown_timeout():
	pode_causar_dano = true

func _on_stun_timer_timeout():
	print(self.name, "não está mais atordoado.") # DEBUG
	atordoado = false
