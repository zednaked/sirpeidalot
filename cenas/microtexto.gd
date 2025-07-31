extends Node2D


func _ready() -> void:
	visible = false

func start (texto : String) -> void:
	visible = true
	modulate = Color.RED
	$texto.text = "[tornado radius=0.7 freq=24.2 connected=1]" + texto + "[/tornado]"
	$texto/animacao.play("sobe")
	
func fim() -> void:
	$texto.text = ""
	visible = false
	pass
	#queue_free()
