extends Sprite2D

#tempo em rodadas
@export var tempo: int

@onready var tempoatual = tempo

func diminuitempo ():
	tempoatual -= 1
	get_parent().get_parent().take_damage(2)
	if tempoatual < 1:
		queue_free()
	
	
