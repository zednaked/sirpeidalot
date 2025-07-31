extends Node

enum tipo_inimigo {
	VAMPIRO,
	ESQUELETO,
	CRANIO
	
}

enum tipo_skill{
	ATAQUE,
	DEFESA,
	RECUPERAVIDA,
	GANHAACAO,
	
}

enum ConteudoSlot {
	COMIDA,
	DINHEIRO,
	BEBIDA,
	EQUIPAMENTO,
	INSUMO
}

enum insumos  {
	OSSOS,
	GRAOS	
}
enum equipamentos {
	ESPADA,
	BOTAS,
	ARMADURA
}

enum comidas {
	TORTA
}

enum bebidas {
	POCAO
	
}



var ouro = 0
var armadura = 0
var dano = 0
var vida = 100
var nome = "player1"

var modo = "join"


var selecionado1
