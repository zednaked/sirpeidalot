# esqueleto.gd - Script de Comportamento do Inimigo
# Este script controla a IA e as ações do inimigo esqueleto.
# Ele gerencia o estado (vida, movimento, morte) e a lógica de decisão
# para atacar ou se mover em direção ao jogador durante seu turno.

extends CharacterBody2D

# --- Sinais ---
# Emitido quando o esqueleto completa sua a��ão no turno.
signal action_taken

# --- Constantes ---
const TILE_SIZE = 16
const MOVE_SPEED = 20.0

# --- Atributos ---
@export var db: PackedScene
@export var drop: PackedScene
@export var health: int = 50 # Pontos de vida do esqueleto.
@export var damage: int = 10 # Dano que o esqueleto causa ao jogador.
@export var detection_range: int = 160 /2 # Distância em pixels para detectar o jogador (5 tiles)
@export var numero_acoes = 2
@onready var arco : PackedScene = preload("res://cenas/arco.tscn")
@export var tipo_inimigo : Goblais.tipo_inimigo
@export var chance_dodge = 10

var acoes_disponiveis = 2 # a cada inicio 

var cooldown_max = 1
var cooldown = 0


# --- Referências ---
@onready var animated_sprite: AnimatedSprite2D = $animacao
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
var player_node: Node2D = null # Referência ao nó do jogador.
var turn_manager = null       # Referência ao TurnManager.

# --- Estado ---
var is_moving: bool = false # Verdadeiro se o esqueleto está se movendo.
var is_dead: bool = false   # Verdadeiro se o esqueleto morreu.
var target_position: Vector2 # Posição alvo para o movimento.
var isinimigo = true


func _ready():
	# Obtém a referência ao jogador e define a posição inicial.
	player_node = get_tree().get_first_node_in_group("player")
	target_position = global_position
	add_to_group("enemies")

func is_p1_bloqueado () -> bool :
	
	return is_bloqueado(player_node.position)

func _physics_process(delta):
	
	if is_p1_bloqueado() : 
		visible = false
	else:
		visible = true
		modulate = Color.WHITE
		
	
	if is_dead:
		if $animacao.get_animation() != "death":
			if is_instance_valid(collision_shape):
				collision_shape.disabled = true
		
			animated_sprite.play("death",1,true)
			
			animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count("death")
		#	_die()
	# Interpola suavemente a posição do esqueleto até o alvo se estiver se movendo.
	
	#$VisionRayCast.force_raycast_update()
	if is_dead:
		#animated_sprite.frame = 3
		return
		
	if is_moving:
		
		if global_position.distance_to(target_position) > 0.1:
			global_position = global_position.lerp(target_position, MOVE_SPEED * delta)
		else:
			# Finaliza o movimento e emite o sinal de ação concluída.
			global_position = target_position
			is_moving = false
			animated_sprite.play("idle")
			if ( acoes_disponiveis <= 0):
				call_deferred("emit_signal", "action_taken")
			else:
				take_turn()

# Função principal chamada pelo TurnManager para que o esqueleto execute seu turno.


func take_turn():
	# Um esqueleto morto não faz nada e termina seu turno imediatamente.
	turn_manager = get_parent().get_parent()
	

		
	for efeito in $efeitos.get_children():
		efeito.diminuitempo()
	
	
	if is_dead:
		call_deferred("emit_signal", "action_taken")
		#emit_signal("action_taken")
		return
		
	
#	print_debug("--- Turno de %s ---" % self.name)
	var player_pos = turn_manager.get_player_position()
	var my_pos = global_position
	var distance_to_player = my_pos.distance_to(player_pos)
#	print_debug("Distância para o jogador: %s, Raio de Detecção: %s" % [distance_to_player, detection_range])
	
	# Se o jogador estiver fora de alcance, não faz nada e passa o turno.
	if distance_to_player > detection_range:
#		print_debug("Ação: Não fazer nada (jogador fora de alcance).")
		call_deferred("emit_signal", "action_taken")
		return
	#tem que mandar async de tudo
	
	# Se o jogador estiver dentro do alcance, decide se ataca ou se move.
	while acoes_disponiveis > 0:
		if is_p1_bloqueado() :
			visible = true
			modulate = Color.DARK_SLATE_GRAY
		
		if is_dead:
			_die()
		var temp = acoes_disponiveis	
		
		if distance_to_player < TILE_SIZE * 1.5 and acoes_disponiveis >= 2:
			
			Eventos.emit_signal("log", str( name + " te atacou"))
			acoes_disponiveis -=2
			await get_tree().create_timer(0.5).timeout
			_attack_player(player_pos - my_pos)
			
			
		if tipo_inimigo == Goblais.tipo_inimigo.VAMPIRO:
			if distance_to_player < (TILE_SIZE * 1.5) * 5 and acoes_disponiveis > 3 and cooldown == 0 and !is_bloqueado(player_node.position) : #faz ele nao atacar sempre de primeira
				#player_node.position.angle_to(position)
				# em quem dispara a flecha, ex:
				
				var flecha = arco.instantiate()
				flecha.position = position
				flecha.shoot (player_node.position)
				get_parent().get_parent().add_child(flecha)
				animated_sprite.play("atack")
				acoes_disponiveis -= 3 #foça ele a atacar e ficar parado
				await get_tree().create_timer(0.2).timeout
				cooldown = cooldown_max
		
		
			
		if distance_to_player > TILE_SIZE * 1.5 and acoes_disponiveis >0:
			acoes_disponiveis -=1
			_move_towards_player(player_pos)
			
		await get_tree().create_timer(0.7).timeout
		
		if acoes_disponiveis == temp : acoes_disponiveis = -1
		
	call_deferred("emit_signal", "action_taken")
	
		
	if get_parent().get_parent().has_node("propagador"):
		turn_manager.atualiza_mapa_geral() #sempre que um 


func is_bloqueado (target_position) -> bool :
	
	$VisionRayCast.set_target_position (target_position - $VisionRayCast.global_position  ) 
	$VisionRayCast.force_raycast_update()
	if $VisionRayCast.is_colliding():
		if "player" in $VisionRayCast.get_collider() :
			return  false
			
		return true	
	return false

func set_anim (animac: String):
	$animacao.play (animac)
	

func doesdodge()  -> bool:
	randomize()
	var temp = randi_range(0,100)
	
	if chance_dodge > temp:
		return true
		
	return false
# Reduz a vida do esqueleto ao receber dano.
func take_damage(amount: int):
	if doesdodge() :
		$microtexto.start("Esquivou !!!")
		return
	
	$microtexto.start("-" + str(amount))
	if is_dead:
		return
		
		
	health -= amount
	#print_debug("%s recebeu %d de dano, vida restante: %d." % [self.name, amount, health])
	
	Eventos.emit_signal("log", str("%s recebeu %d de dano, vida restante: %d." % [self.name, amount, health]))
	
	
	if health <= 0:
		_die()
	else:
		set_anim("hurt")
		get_parent().get_parent().get_node("they").play()
		await get_tree().create_timer(0.3).timeout
		
		

# Executa a lógica de ataque contra o jogador.

func _attack_player(direction: Vector2):
	_update_animation_direction(direction.normalized()) #todo fazer isso no player
	var anim_name = "attack"
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
		if player_node.has_method("take_damage"):
			player_node.take_damage(damage)
		await animated_sprite.animation_finished
		get_parent().get_parent().get_node("dano").play()
	else:
		# Fallback caso a anima��ão de ataque não exista.
		await get_tree().create_timer(0.5).timeout

	#var filhodaputa = db.instantiate()
	#player_node.get_node("debuffs").add_child(filhodaputa)	
	#filhodaputa.position.x = 0
	#filhodaputa.position.y = 0
	animated_sprite.play("idle")
#	if ( acoes_disponiveis <= 0):
#		emit_signal("action_taken")
#	else:
#		take_turn()

# Altera o estado do esqueleto para 'morto'.
# Desativa sua colisão e executa a animação de morte.
func _die_async ():
	is_dead = true
	numero_acoes = -1 
	queue_free()
	if is_instance_valid(collision_shape):
		collision_shape.disabled = true
		
	if is_instance_valid(animated_sprite):
		animated_sprite.play("death",3,true)
		animated_sprite.frame = 3


	
func _die():
	get_parent().get_parent().get_node("morre").play()
	numero_acoes = -10
	#if is_dead: return
	is_dead = true
	drop = load("res://cenas/ouro.tscn")
	#print_debug("%s está morrendo." % self.name)
	Eventos.emit_signal("log", str( name + " morreu !"))
	
	if is_instance_valid(collision_shape):
		collision_shape.disabled = true
		
	animated_sprite.play("death",1,true)
	animated_sprite.frame = 3	
	
	if drop :
		var droptemp = drop.instantiate()
		droptemp.position.x = position.x -7
		droptemp.position.y = position.y - 7
		get_parent().get_parent().add_child(droptemp)
			
		
			#var filhodaputa = debuff.instantiate()
			
			#collider.get_node("efeitos").add_child(filhodaputa)
			#filhodaputa.position.x = 0
			#filhodaputa.position.y = 0
	
	
	
	if get_parent().get_parent().has_node("propagador"):
		turn_manager.atualiza_mapa_geral()
	#todo:

# --- Funções de Movimento e Auxiliares ---

# Move o esqueleto um passo em direção ao jogador usando o caminho A*.
func _move_towards_player(player_pos: Vector2):
	
	if not turn_manager:
		emit_signal("action_taken")
		return
	
	
	var path = turn_manager.calculate_path(global_position, player_pos)
	#print_debug("Path for ", self.name, ": ", path)
	
	if path.size() > 1:
		# Define o próximo passo do caminho como o alvo.
		target_position = path[1]
	
		#adicionar a vision aqui
		
		$VisionRayCast.set_target_position (path[1] - $VisionRayCast.global_position  ) 
		$VisionRayCast.force_raycast_update()
		if $VisionRayCast.is_colliding():
			print ("bloqueado")
			#emit_signal("action_taken")
			#call_deferred("emit_signal", "action_taken")
			return
			
		is_moving = true
		_update_animation_direction((target_position - global_position).normalized())
		animated_sprite.play("walk")
		get_parent().get_parent().get_node("they").play()
		Eventos.emit_signal("log", str( name + " moveu-se em sua direção"))
		await get_tree().create_timer(0.5).timeout
	#else:
		# Se não houver caminho, simplesmente termina o turno.
	#	call_deferred("emit_signal", "action_taken")

# Vira o sprite do esqueleto para a esquerda ou direita com base na direção.
func _update_animation_direction(direction: Vector2):
	if direction.x < -0.1:
		animated_sprite.flip_h = true
	elif direction.x > 0.1:
		animated_sprite.flip_h = false

# Define a referência ao TurnManager.
func set_turn_manager(manager):
	turn_manager = manager


func _on_animacao_animation_finished() -> void:
	if $animacao.animation == "death":
		#$animacao.frame  = 3
		print ("mortis")
		#get_parent().is_dead = true	
