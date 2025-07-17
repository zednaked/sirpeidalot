extends StaticBody2D
func collect():
	# Se este objeto for uma porta, atualiza a grade de navegação antes de desaparecer.
	if is_in_group("traps"):
		$animacao.play("trapchao")	
