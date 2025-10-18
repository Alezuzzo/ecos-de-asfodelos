# CardDB.gd
extends Node

# A chance de uma carta corrompida aparecer (0.25 = 25%)
# Você pode ajustar este valor para balancear o jogo!
const CHANCE_CARTA_CORROMPIDA = 0.25

# Baralho de cartas normais
const CARDS = {
	"vontade_de_ferro": {
		"nome": "Vontade de Ferro",
		"descricao": "Sua determinação fortalece sua alma. (+1 Coração Máximo)",
		"afinidade": "Resiliência",
		"imagem": "res://assets/cartas/afinidade resiliencia/vontadedeferro.png"
	},
	"guardiao_caido": {
		"nome": "Guardião Caído",
		"descricao": "Ao ser atingido, libera uma onda de choque que repele inimigos.",
		"afinidade": "Resiliência",
		"imagem": "res://assets/cartas/afinidade resiliencia/GuardiaoCaido.png"
	},
	"foco_do_penitente": {
		"nome": "Foco do Penitente",
		"descricao": "Após 7s sem receber dano, seu próximo tiro causa 3x mais dano.",
		"afinidade": "Resiliência",
		"imagem": "res://assets/cartas/afinidade resiliencia/focopenitente.png"
	},
}

# Baralho de cartas corrompidas
const CORRUPTED_CARDS = {
	"coroa_do_martir": {
		"nome": "Coroa do Mártir",
		"descricao": "PODER: Seus projéteis são teleguiados. PREÇO: Você não pode mais se curar.",
		"afinidade": "Corrompida",
		"tipo": "corrompida",
		"imagem": "res://assets/cartas/corrompidas/coroa_do_martir.png",
		"animado": true
	},
}

# --- FUNÇÃO DE SORTEIO RESTAURADA PARA A VERSÃO FINAL E ALEATÓRIA ---
func sortear_cartas(quantidade = 3):
	var sorteadas = []
	
	# Decide se uma carta corrompida vai aparecer
	if randf() < CHANCE_CARTA_CORROMPIDA and CORRUPTED_CARDS.size() > 0:
		# Sim! Sorteia 1 carta corrompida e 2 normais.
		print("DEBUG: Uma carta corrompida foi sorteada!")
		
		var chaves_corrompidas = CORRUPTED_CARDS.keys()
		chaves_corrompidas.shuffle()
		sorteadas.append(chaves_corrompidas[0])
		
		var chaves_normais = CARDS.keys()
		chaves_normais.shuffle()
		sorteadas.append(chaves_normais[0])
		sorteadas.append(chaves_normais[1])
		
		# Embaralha o resultado final para que a corrompida não seja sempre a primeira
		sorteadas.shuffle()
	else:
		# Não, serão 3 cartas normais.
		print("DEBUG: Nenhuma carta corrompida foi sorteada.")
		
		var chaves = CARDS.keys()
		chaves.shuffle()
		for i in range(min(quantidade, chaves.size())):
			sorteadas.append(chaves[i])
			
	return sorteadas

# Função auxiliar (permanece igual)
func get_card_info(id_carta):
	if CARDS.has(id_carta):
		return CARDS[id_carta]
	if CORRUPTED_CARDS.has(id_carta):
		return CORRUPTED_CARDS[id_carta]
	return null
