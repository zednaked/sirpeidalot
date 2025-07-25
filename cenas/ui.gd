extends Control
var pause: bool = false
func _on_slot_3_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("clique_esquerdo"):
		pause = !pause 
		$inventario.visible =pause
		$topo/slot4.visible = pause
		
		$topo/slot2.visible = pause
		$topo/setup.visible = pause


func _on_setup_gui_input(event: InputEvent) -> void:

	pass # Replace with function body.
