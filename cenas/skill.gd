extends Panel

@export var tipo : Goblais.tipo_skill = Goblais.tipo_skill.ATAQUE
@export var quantidade : int = 5

@export var cooldown : int = 2

var cooldown_atual = 0

var usou = false

func usar() -> bool :
	if cooldown_atual == 0 :
		cooldown_atual = cooldown
		self_modulate  = Color.DIM_GRAY
		return true
		
	return false

func diminui() -> bool:
	if cooldown_atual != 0:
		cooldown_atual -= 1	
		return true
		
	else:
		self_modulate = Color.WHITE
		usou = false
		return false
		
