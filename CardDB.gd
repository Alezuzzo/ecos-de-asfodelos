# CardDB.gd
extends Node

const CHANCE_CARTA_CORROMPIDA = 0.25

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

const CORRUPTED_CARDS = {
	"coroa_do_martir": {
		"nome": "Coroa do Mártir",
		"descricao": "PODER: Seus projéteis são teleguiados. PREÇO: Você não pode mais se curar.",
		"afinidade": "Corrompida",
		"tipo": "corrompida",
		"imagem": "res://assets/cartas/afinidade resiliencia/vontadedeferro.png"
	},
	"coracao_de_vidro": {
		"nome": "Coração de Vidro",
		"descricao": "PODER: Todo o seu dano é dobrado. PREÇO: Todo dano que você recebe é dobrado.",
		"afinidade": "Corrompida",
		"tipo": "corrompida",
		"imagem": "res://assets/cartas/afinidade resiliencia/vontadedeferro.png"
	},
	"abraco_do_vazio": {
		"nome": "Abraço do Vazio",
		"descricao": "PODER: Uma aura de dano orbita você. PREÇO: Sua cadência de tiro e velocidade dos projéteis são reduzidas pela metade.",
		"afinidade": "Corrompida",
		"tipo": "corrompida",
		"imagem": "res://assets/cartas/afinidade resiliencia/vontadedeferro.png"
	},
}

func sortear_cartas(quantidade = 3):
	var sorteadas = []
	if randf() < CHANCE_CARTA_CORROMPIDA and CORRUPTED_CARDS.size() > 0:
		var chaves_corrompidas = CORRUPTED_CARDS.keys()
		chaves_corrompidas.shuffle()
		sorteadas.append(chaves_corrompidas[0])
		
		var chaves_normais = CARDS.keys()
		chaves_normais.shuffle()
		sorteadas.append(chaves_normais[0])
		sorteadas.append(chaves_normais[1])
		
		sorteadas.shuffle()
	else:
		var chaves = CARDS.keys()
		chaves.shuffle()
		for i in range(min(quantidade, chaves.size())):
			sorteadas.append(chaves[i])
	return sorteadas

func get_card_info(id_carta):
	if CARDS.has(id_carta):
		return CARDS[id_carta]
	if CORRUPTED_CARDS.has(id_carta):
		return CORRUPTED_CARDS[id_carta]
	return null
