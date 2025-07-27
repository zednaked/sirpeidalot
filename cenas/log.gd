extends RichTextLabel



func _ready() -> void:
	Eventos.connect("log",add_log)
	
func add_log (texto):
	text = str ("[tornado radius=1 freq=2.8 connected=1]" +  texto + "[/tornado]")
