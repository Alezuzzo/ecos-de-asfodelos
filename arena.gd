# arena.gd
extends Node2D

# Agora usamos um array para colocar todas as cenas de inimigos
@export var cenas_inimigos: Array[PackedScene]
@export var cena_fonte_vida: PackedScene

# Variáveis para controlar as ondas
var onda_atual = 0
var inimigos_vivos = 0
var base_inimigos_por_onda = 3

var tamanho_tela

func _ready():
	tamanho_tela = get_viewport_rect().size
	$TelaMelhorias.melhoria_selecionada.connect(_on_melhoria_selecionada)
	$StartTimer.start()
	# Inicia o timer que vai tentar criar eventos dinâmicos
	$EventoTimer.start()

func iniciar_nova_onda():
	onda_atual += 1
	print("--- INICIANDO ONDA ", onda_atual, " ---")
	var quantidade_a_spawnar = base_inimigos_por_onda + (onda_atual * 2)
	inimigos_vivos = quantidade_a_spawnar
	
	for i in range(quantidade_a_spawnar):
		spawnar_inimigo()
		await get_tree().create_timer(0.3).timeout

func spawnar_inimigo():
	# Escolhe um inimigo aleatório do nosso array
	var inimigo_escolhido = cenas_inimigos.pick_random()
	if not inimigo_escolhido: return # Segurança se o array estiver vazio
	
	var inimigo = inimigo_escolhido.instantiate()
	inimigo.connect("morreu", _on_inimigo_morreu)
	
	var spawn_pos = Vector2()
	var borda = randi() % 4
	match borda:
		0: spawn_pos = Vector2(randf_range(0, tamanho_tela.x), -50)
		1: spawn_pos = Vector2(randf_range(0, tamanho_tela.x), tamanho_tela.y + 50)
		2: spawn_pos = Vector2(-50, randf_range(0, tamanho_tela.y))
		3: spawn_pos = Vector2(tamanho_tela.x + 50, randf_range(0, tamanho_tela.y))
			
	inimigo.global_position = spawn_pos
	inimigo.jogador = $Jogador
	add_child(inimigo)

# Função para tentar criar um evento
func _on_evento_timer_timeout():
	# 30% de chance de criar uma fonte de vida
	if randf() < 0.3:
		var fonte = cena_fonte_vida.instantiate()
		# Posição aleatória dentro da tela
		fonte.global_position = Vector2(
			randf_range(50, tamanho_tela.x - 50),
			randf_range(50, tamanho_tela.y - 50)
		)
		add_child(fonte)
		print("FONTE DE VIDA APARECEU!")

func _on_inimigo_morreu():
	inimigos_vivos -= 1
	if inimigos_vivos <= 0:
		get_tree().paused = true
		$TelaMelhorias.show()

func _on_start_timer_timeout():
	iniciar_nova_onda()
	
func _on_melhoria_selecionada(tipo_melhoria: String):
	var jogador = $Jogador
	match tipo_melhoria:
		"velocidade_tiro":
			jogador.cadencia_tiro = max(0.1, jogador.cadencia_tiro * 0.85)
		"velocidade_movimento":
			jogador.velocidade *= 1.15
		"dano_projetil":
			jogador.dano_projetil += 1
	iniciar_nova_onda()
