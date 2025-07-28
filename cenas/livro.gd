extends Node2D
var aberto= false

func _physics_process(delta: float) -> void:
	if aberto: return
	
	if $RayCast2D.is_colliding():
		aberto = true
		$off.visible =  false
		$on.visible = true
		Eventos.emit_signal("popup","Ficar só jogando sem se divertir faz de voce um idiota")		
	
