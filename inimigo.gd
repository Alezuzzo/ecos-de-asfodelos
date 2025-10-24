extends CharacterBody2D

signal morreu

# --- Variáveis Editáveis ---
@export var velocidade = 150
@export var vida = 3
@export var dano_por_toque = 1
@export var stop_distance = 30.0
@export var pushback_force = 600.0
@export var stun_duration = 0.4

# --- Variáveis Internas ---
var jogador = null
var pode_causar_dano = true
var atordoado = false

var damage_number_scene = preload("res://DamageNumber.tscn") 

@onready var spawn_sound_player = $SpawnSoundPlayer
@onready var death_sound_player = $DeathSoundPlayer


func _ready():
	if spawn_sound_player: spawn_sound_player.play()


func aplicar_repulsao(direcao, forca):
	if atordoado: return
	atordoado = true
	move_and_collide(direcao * forca * get_physics_process_delta_time())
	if has_node("StunTimer"): $StunTimer.start(0.3)

func sofrer_dano(dano):
	if damage_number_scene:
		var damage_num = damage_number_scene.instantiate()
		get_parent().add_child(damage_num)

		damage_num.global_position = global_position + Vector2(randf_range(-15, 15), -40)
		damage_num.set_damage(dano)


	vida -= dano
	hit_flash()
	if vida <= 0 and not is_queued_for_deletion():
		emit_signal("morreu")
		set_physics_process(false)
		collision_layer = 0
		collision_mask = 0
		var sprite_node = $AnimatedSprite2D if has_node("AnimatedSprite2D") else ($Sprite2D if has_node("Sprite2D") else $ColorRect)
		if sprite_node: sprite_node.hide()
		if has_node("PeriodicSoundTimer"): $PeriodicSoundTimer.stop()

		if death_sound_player:
			death_sound_player.play()
			await death_sound_player.finished
		
		queue_free()

func hit_flash():
	var tween = create_tween()
	var sprite_node = $AnimatedSprite2D if has_node("AnimatedSprite2D") else ($Sprite2D if has_node("Sprite2D") else $ColorRect)
	if sprite_node:
		tween.tween_property(sprite_node, "modulate", Color.WHITE, 0.1)
		tween.tween_property(sprite_node, "modulate", Color(1,1,1,1), 0.1)

# FUNÇÃO PRINCIPAL (_physics_process)
func _physics_process(delta):
	if atordoado:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if is_instance_valid(jogador):
		var direcao_para_jogador = global_position.direction_to(jogador.global_position)
		var distancia_para_jogador = global_position.distance_to(jogador.global_position)
		if distancia_para_jogador > stop_distance + 5:
			velocity = direcao_para_jogador * velocidade
		elif distancia_para_jogador < stop_distance - 5:
			velocity = -direcao_para_jogador * (velocidade / 2)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, velocidade * 3 * delta)
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	for i in range(get_slide_collision_count()):
		var colisao = get_slide_collision(i)
		var collider = colisao.get_collider()
		if is_instance_valid(collider) and collider.is_in_group("jogador"):
			if pode_causar_dano:
				collider.sofrer_dano(dano_por_toque)
				pode_causar_dano = false
				if has_node("DanoCooldown"): $DanoCooldown.start()
				atordoado = true
				var push_direction = global_position.direction_to(collider.global_position).rotated(PI)
				move_and_collide(push_direction * pushback_force * delta)
				velocity = Vector2.ZERO
				if has_node("StunTimer"): $StunTimer.start(stun_duration)
				break


# FUNÇÕES CONECTADAS A SINAIS (Callbacks dos Timers)
func _on_dano_cooldown_timeout():
	pode_causar_dano = true

func _on_stun_timer_timeout():
	atordoado = false

func _on_periodic_sound_timer_timeout():
	if spawn_sound_player and not spawn_sound_player.playing:
		spawn_sound_player.play()
