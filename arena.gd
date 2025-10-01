# arena.gd
extends Node2D

@export var inimigo_cena: PackedScene

# Variáveis para controlar as ondas
var onda_atual = 0
var inimigos_vivos = 0
var base_inimigos_por_onda = 3

var tamanho_tela

func _ready():
	tamanho_tela = get_viewport_rect().size
	# Conecta o sinal da tela de melhorias ANTES de qualquer coisa
	$TelaMelhorias.melhoria_selecionada.connect(_on_melhoria_selecionada)
	# Espera um pouco antes de começar a primeira onda
	$StartTimer.start()

# Função para começar uma nova onda
func iniciar_nova_onda():
	onda_atual += 1
	print("--- INICIANDO ONDA ", onda_atual, " ---")
	
	# A quantidade de inimigos aumenta a cada onda
	var quantidade_a_spawnar = base_inimigos_por_onda + (onda_atual * 2)
	inimigos_vivos = quantidade_a_spawnar
	
	for i in range(quantidade_a_spawnar):
		spawnar_inimigo()
		# Pequeno atraso entre cada spawn para não virem todos de uma vez
		await get_tree().create_timer(0.3).timeout

# Função que cria um único inimigo
func spawnar_inimigo():
	var inimigo = inimigo_cena.instantiate()
	
	# Conecta o sinal "morreu" do inimigo à nossa função de contagem
	inimigo.connect("morreu", _on_inimigo_morreu)
	
	# Lógica de spawn (mesma de antes)
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

# Função chamada quando um inimigo morre
func _on_inimigo_morreu():
	inimigos_vivos -= 1
	print("Inimigo derrotado! Restam: ", inimigos_vivos)
	
	# Se não houver mais inimigos, a onda acabou!
	if inimigos_vivos <= 0:
		print("--- ONDA ", onda_atual, " COMPLETA! ---")
		get_tree().paused = true
		$TelaMelhorias.show()

# Função chamada pelo timer inicial
func _on_start_timer_timeout():
	iniciar_nova_onda()
	
# Função que recebe o sinal da TelaMelhorias e aplica o upgrade
func _on_melhoria_selecionada(tipo_melhoria: String):
	print("Melhoria selecionada: ", tipo_melhoria)
	var jogador = $Jogador
	
	match tipo_melhoria:
		"velocidade_tiro":
			# Diminui o tempo de espera, então atira mais rápido
			jogador.cadencia_tiro = max(0.1, jogador.cadencia_tiro * 0.85)
		"velocidade_movimento":
			jogador.velocidade *= 1.15
		"dano_projetil":
			# Esta melhoria ainda é conceitual, vamos preparar para o futuro
			jogador.dano_projetil += 1

	# Começa a próxima onda!
	iniciar_nova_onda()
