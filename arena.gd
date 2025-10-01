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
		# PAUSA O JOGO E MOSTRA A TELA DE MELHORIAS (AINDA VAMOS CRIAR)
		get_tree().paused = true
		# AQUI VAMOS CHAMAR A TELA DA CARTOMANTE NO PRÓXIMO PASSO


# Função chamada pelo timer inicial
func _on_start_timer_timeout():
	iniciar_nova_onda()
