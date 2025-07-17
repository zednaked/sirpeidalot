# todo: filtrar coisas do mesmo tipo sendo equipadas

extends Panel

@export var tipo: Goblais.ConteudoSlot
@export var qtd: int = 1
@export var dano: int = 0
@export var vida: int = 0
@export var armadura: int = 0
var tooltiplabel = ""

var selecionado = false

func _ready() -> void:
	if tipo == Goblais.ConteudoSlot.ESPADA:
		$icone.region_rect = Rect2 (48.0,0.0,16,16)
		tooltiplabel = "Espada"
		
	elif tipo == Goblais.ConteudoSlot.COMIDA:
		$icone.region_rect = Rect2 (64.0,528.0,16,16)
		tooltiplabel = "Comida"
		
	elif tipo == Goblais.ConteudoSlot.DINHEIRO:
		$icone.region_rect = Rect2 (64.0,128.0,16,16)
		tooltiplabel = "Ouro"
	elif tipo == Goblais.ConteudoSlot.BOTAS:
		$icone.region_rect = Rect2 (96.0,2048.0,16,16)
		tooltiplabel = "Botas"
	elif tipo == Goblais.ConteudoSlot.ARMADURA:
		$icone.region_rect = Rect2 (32.0,1856.0,16,16)
		tooltiplabel = "Armadura"
		

func _on_mouse_entered() -> void:
	$tooltip.visible = true
	$tooltip/Label.text = tooltiplabel
	pass # Replace with function body.



func _on_mouse_exited() -> void:
	$tooltip.visible = false
	pass # Replace with function body.
	
func _process(delta: float) -> void:
	
	if selecionado:
		modulate = Color(.0,.93,.73,1)	
		Goblais.selecionado1 = $"."
		
		
		
	else:
		modulate =Color(.8,.8,.8,1)	
		
		
	
	

func qtoequipado() -> int :
	return %equipado.get_child_count()
	
	
	#return 0

func _on_gui_input(event: InputEvent) -> void:
	var e = event 
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.double_click:
		var onde = Goblais.selecionado1.get_parent().name
		if onde == "mochila":
			if qtoequipado() < 3:
				reparent (%equipado)
		else:
			reparent(%mochila)
		Goblais.selecionado1.selecionado = false
		Goblais.selecionado1 = 0 
		
		return
	
	if event.is_action_pressed("clique_esquerdo"):
		
		selecionado = !selecionado
		
		if Goblais.selecionado1:
			print_debug("troca")
			selecionado = false
			var temp = Goblais.selecionado1.get_parent()
			
			Goblais.selecionado1.reparent (get_parent())
			reparent(temp)
			Goblais.selecionado1.selecionado = false
			Goblais.selecionado1 = 0 
			
			return 

		
	pass # Replace with function body.
