# atirador.gd
extends CharacterBody2D

signal morreu

# --- Variáveis Editáveis no Inspetor ---
@export var velocidade = 100
@export var distancia_ideal = 300 # Distância que ele tenta manter do jogador
@export var cadencia_tiro = 1.5   # Tempo entre os tiros
@export var vida = 2

# --- Variáveis Internas ---
var jogador = null
var pode_atirar = true
var atordoado = false # Para stun da onda de choque/repulsão

var projetil_inimigo_cena = preload("res://projetil_inimigo.tscn")

# --- REFERÊNCIAS PARA OS PLAYERS DE SOM ---
@onready var spawn_sound_player = $SpawnSoundPlayer
@onready var death_sound_player = $DeathSoundPlayer
# ------------------------------------------

#-----------------------------------------------------------------------------
# FUNÇÃO _ready() - Toca o som de spawn
#-----------------------------------------------------------------------------
func _ready():
	# Toca o som de entrada na cena assim que o atirador é criado.
	spawn_sound_player.play()

#-----------------------------------------------------------------------------
# FUNÇÕES DE LÓGICA
#-----------------------------------------------------------------------------

# Função chamada pela Onda de Choque
func aplicar_repulsao(direcao, forca):
	if atordoado: return
	atordoado = true
	move_and_collide(direcao * forca * get_physics_process_delta_time())
	# Garante que o StunTimer exista antes de usá-lo
	if has_node("StunTimer"):
		$StunTimer.start(0.3) # Duração do stun da Onda de Choque
	else:
		print("AVISO em Atirador: Nó StunTimer não encontrado.")


func sofrer_dano(dano):
	vida -= dano
	hit_flash() # Chama o efeito visual

	if vida <= 0:
		# --- LÓGICA DE MORTE COM SOM ---
		# 1. Emite o sinal para a Arena saber que morreu (para contagem)
		emit_signal("morreu")

		# 2. Desativa a capacidade de causar dano/colidir enquanto o som toca
		set_physics_process(false) # Para a lógica de IA e movimento
		collision_layer = 0 # Deixa de colidir com outros
		collision_mask = 0 # Deixa de detectar outros
		# Esconde o sprite para dar a impressão de desaparecimento
		if has_node("AnimatedSprite2D"): $AnimatedSprite2D.hide()
		elif has_node("Sprite2D"): $Sprite2D.hide()
		elif has_node("ColorRect"): $ColorRect.hide()


		# 3. Toca o som de morte
		death_sound_player.play()

		# 4. AGUARDA o som terminar antes de se deletar da cena
		await death_sound_player.finished

		# 5. Finalmente, se remove completamente
		queue_free()
		# --- FIM DA LÓGICA DE MORTE ---

# --- FUNÇÃO HIT_FLASH CORRIGIDA ---
func hit_flash():
	var tween = create_tween()
	# Tenta encontrar o nó visual correto (Sprite ou ColorRect)
	var sprite_node = $AnimatedSprite2D if has_node("AnimatedSprite2D") else ($Sprite2D if has_node("Sprite2D") else $ColorRect)
	if is_instance_valid(sprite_node): # Só aplica se encontrar o nó
		tween.tween_property(sprite_node, "modulate", Color.WHITE, 0.1)
		tween.tween_property(sprite_node, "modulate", Color(1,1,1,1), 0.1)
	# Removi o print de aviso para não poluir o console

#-----------------------------------------------------------------------------
# FUNÇÃO PRINCIPAL (_physics_process)
#-----------------------------------------------------------------------------

func _physics_process(delta):
	# --- LÓGICA DE STUN ---
	if atordoado:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	# --- FIM DA LÓGICA DE STUN ---

	# Lógica de Movimento e Tiro
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

func atirar():
	if not is_instance_valid(jogador): return
	pode_atirar = false

	var projetil = projetil_inimigo_cena.instantiate()
	projetil.position = position
	projetil.look_at(jogador.global_position)

	# Adiciona o projétil como irmão para que ele seja afetado pelo YSort
	get_parent().add_child(projetil)

	# Garante que o TiroTimer exista antes de usá-lo
	if has_node("TiroTimer"):
		$TiroTimer.start(cadencia_tiro)
	else:
		print("AVISO em Atirador: Nó TiroTimer não encontrado.")


#-----------------------------------------------------------------------------
# FUNÇÕES DE SINAIS (Callbacks dos Timers)
#-----------------------------------------------------------------------------

func _on_tiro_timer_timeout():
	pode_atirar = true

func _on_stun_timer_timeout():
	atordoado = false
