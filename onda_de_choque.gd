# onda_de_choque.gd
extends Area2D

# Parâmetros da Onda de Choque
@export var forca_repulsao = 3500.0
@export var raio_final = 300.0
@export var duracao = 0.4

# --- A CORREÇÃO PRINCIPAL ESTÁ AQUI ---
# Usamos @onready para garantir que o Godot só pegue a referência
# desses nós quando a cena estiver completamente pronta.
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D # Certifique-se de que seu nó visual se chama "Sprite2D"

#-----------------------------------------------------------------------------
# FUNÇÕES DO GODOT
#-----------------------------------------------------------------------------

func _ready():
	# Desativa a colisão no início
	collision_shape.disabled = true
	
	# Garante que a onda comece pequena e semitransparente
	scale = Vector2.ZERO
	modulate.a = 0.5
	
	# Inicia a animação
	animar_onda()

func _on_body_entered(body):
	if body.is_in_group("inimigos"):
		if body.has_method("aplicar_repulsao"):
			print("Onda de Choque atingiu:", body.name) # DEBUG: Ver se está detectando
			var direcao = global_position.direction_to(body.global_position)
			body.aplicar_repulsao(direcao, forca_repulsao)

#-----------------------------------------------------------------------------
# FUNÇÕES CUSTOMIZADAS
#-----------------------------------------------------------------------------

func animar_onda():
	# Ativa a colisão após um pequeno atraso para dar tempo de a animação começar
	await get_tree().create_timer(0.05).timeout
	collision_shape.disabled = false
	
	# Cria uma animação (Tween) para expandir e desaparecer a onda ao mesmo tempo
	var tween = create_tween().set_parallel(true)
	
	# Pega a largura da textura da sprite para calcular a escala correta
	var sprite_width = 1.0 # Valor de segurança
	if sprite.texture:
		sprite_width = sprite.texture.get_width()

	# Anima o tamanho (escala) para que o diâmetro da sprite chegue ao raio_final * 2
	tween.tween_property(self, "scale", Vector2.ONE * (raio_final * 2 / sprite_width), duracao)
	# Anima a transparência (alpha) de 0.5 para 0 (invisível)
	tween.tween_property(self, "modulate:a", 0, duracao).from(0.5)
	
	# Quando a animação terminar, o tween emitirá um sinal 'finished'.
	# Aguardamos esse sinal e então destruímos a cena da onda de choque.
	await tween.finished
	queue_free()
