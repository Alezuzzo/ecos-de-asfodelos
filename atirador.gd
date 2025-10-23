# atirador.gd
extends CharacterBody2D

signal morreu

# --- Variáveis Editáveis no Inspetor ---
@export var velocidade = 100
@export var distancia_ideal = 300
@export var cadencia_tiro = 1.5
@export var vida = 2

# --- Variáveis Internas ---
var jogador = null
var pode_atirar = true
var atordoado = false

var projetil_inimigo_cena = preload("res://projetil_inimigo.tscn")
# --- REFERÊNCIA PARA A CENA DO NÚMERO DE DANO ---
var damage_number_scene = preload("res://DamageNumber.tscn") # Verifique o caminho!

# --- REFERÊNCIAS PARA OS PLAYERS DE SOM ---
@onready var spawn_sound_player = $SpawnSoundPlayer
@onready var death_sound_player = $DeathSoundPlayer

#-----------------------------------------------------------------------------
# FUNÇÃO _ready() - Toca o som de spawn
#-----------------------------------------------------------------------------
func _ready():
	if spawn_sound_player: spawn_sound_player.play()

#-----------------------------------------------------------------------------
# FUNÇÕES DE LÓGICA
#-----------------------------------------------------------------------------

func aplicar_repulsao(direcao, forca):
	if atordoado: return
	atordoado = true
	move_and_collide(direcao * forca * get_physics_process_delta_time())
	if has_node("StunTimer"): $StunTimer.start(0.3)
	else: print("AVISO em Atirador: Nó StunTimer não encontrado.")

func sofrer_dano(dano):
	# --- CÓDIGO PARA CRIAR O NÚMERO DE DANO ---
	if damage_number_scene:
		var damage_num = damage_number_scene.instantiate()
		get_parent().add_child(damage_num) # Adiciona como irmão
		# Posição ligeiramente acima e aleatória horizontalmente
		damage_num.global_position = global_position + Vector2(randf_range(-15, 15), -40)
		damage_num.set_damage(dano)
	# --- FIM DO CÓDIGO DO NÚMERO ---

	vida -= dano
	hit_flash()

	if vida <= 0 and not is_queued_for_deletion(): # Evita lógica de morte dupla
		emit_signal("morreu")
		set_physics_process(false)
		collision_layer = 0
		collision_mask = 0
		var sprite_node = $AnimatedSprite2D if has_node("AnimatedSprite2D") else ($Sprite2D if has_node("Sprite2D") else $ColorRect)
		if sprite_node: sprite_node.hide()

		if death_sound_player:
			death_sound_player.play()
			await death_sound_player.finished
		
		queue_free()

func hit_flash():
	var tween = create_tween()
	var sprite_node = $AnimatedSprite2D if has_node("AnimatedSprite2D") else ($Sprite2D if has_node("Sprite2D") else $ColorRect)
	if is_instance_valid(sprite_node):
		tween.tween_property(sprite_node, "modulate", Color.WHITE, 0.1)
		tween.tween_property(sprite_node, "modulate", Color(1,1,1,1), 0.1)

#-----------------------------------------------------------------------------
# FUNÇÃO PRINCIPAL (_physics_process)
#-----------------------------------------------------------------------------
# ... (_physics_process permanece igual ao seu código anterior) ...
func _physics_process(delta):
	if atordoado:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if is_instance_valid(jogador):
		var direcao_para_jogador = global_position.direction_to(jogador.global_position)
		var distancia = global_position.distance_to(jogador.global_position)
		if distancia > distancia_ideal + 20:
			velocity = direcao_para_jogador * velocidade
		elif distancia < distancia_ideal - 20:
			velocity = -direcao_para_jogador * velocidade
		else:
			velocity = velocity.move_toward(Vector2.ZERO, velocidade * 2 * delta)
			if pode_atirar:
				atirar()
	else:
		velocity = Vector2.ZERO
	move_and_slide()
#-----------------------------------------------------------------------------
# FUNÇÃO DE TIRO
#-----------------------------------------------------------------------------
# ... (atirar permanece igual ao seu código anterior) ...
func atirar():
	if not is_instance_valid(jogador): return
	pode_atirar = false
	var projetil = projetil_inimigo_cena.instantiate()
	projetil.position = position
	projetil.look_at(jogador.global_position)
	get_parent().add_child(projetil)
	if has_node("TiroTimer"):
		$TiroTimer.start(cadencia_tiro)
	else:
		print("AVISO em Atirador: Nó TiroTimer não encontrado.")
#-----------------------------------------------------------------------------
# FUNÇÕES DE SINAIS (Callbacks dos Timers)
#-----------------------------------------------------------------------------
# ... (_on_tiro_timer_timeout e _on_stun_timer_timeout permanecem iguais) ...
func _on_tiro_timer_timeout():
	pode_atirar = true

func _on_stun_timer_timeout():
	atordoado = false
