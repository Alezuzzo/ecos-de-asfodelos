# damage_number.gd
extends Node2D

@onready var label: Label = $Label # Usar ': Label' ajuda a evitar erros futuros

# Variáveis para controlar a animação
@export var speed = 100.0 # Velocidade de subida em pixels por segundo
@export var duration = 0.6 # Duração total em segundos antes de desaparecer
@export var fade_start_time = 0.3 # Ponto (0.0 a 1.0) da duração onde começa a desaparecer

func _ready():
	# Inicia a animação de movimento e desaparecimento
	animate()

# Função que recebe o valor do dano
func set_damage(damage_amount: int): # Adicionar ': int' melhora a segurança
	label.text = "-" + str(damage_amount) # Mostra o dano com um sinal de menos

func _process(delta):
	# Move o número para cima a cada frame
	position.y -= speed * delta

# --- FUNÇÃO ANIMATE CORRIGIDA PARA GODOT 4 ---
func animate():
	# Cria um Timer que destruirá o nó após a duração total.
	# Isso substitui a necessidade do 'await tween.finished'.
	get_tree().create_timer(duration).timeout.connect(queue_free)

	# Cria um Tween separado apenas para animar o desaparecimento (fade out).
	var fade_tween = create_tween()
	
	# Adiciona um intervalo (atraso) antes de a animação de fade começar.
	# Ex: Se duration=0.6 e fade_start_time=0.3, o atraso será 0.18s
	fade_tween.tween_interval(duration * fade_start_time)
	
	# Anima a propriedade 'modulate:a' (alfa/transparência) de 1 (visível)
	# para 0 (invisível) durante o tempo restante.
	# Ex: Se duration=0.6 e fade_start_time=0.3, a duração do fade será 0.42s
	fade_tween.tween_property(self, "modulate:a", 0.0, duration * (1.0 - fade_start_time)).from(1.0)
# --- FIM DA CORREÇÃO ---
