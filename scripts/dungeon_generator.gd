# dungeon_generator.gd -> Gerenciador de Turnos e Estado do Jogo
# Este script orquestra o fluxo do jogo baseado em turnos, gerencia o estado
# geral e fornece serviços de pathfinding para os inimigos.

extends Node2D

# --- Referências de Nós (Configuradas no Editor) ---
@export var player: CharacterBody2D
@export var player2: CharacterBody2D

@export var enemies_container: Node
@export var floor_tilemap: TileMapLayer  # Camada com os tiles de chão (andáveis)
@export var walls_tilemap: TileMapLayer  # Camada com paredes e obstáculos

@export var nini: int = 5

var packedp1 : PackedScene = preload("res://cenas/Jogador.tscn")
var packedp2 : PackedScene = preload("res://cenas/player2.tscn")

var inimigo1 : PackedScene = preload("res://cenas/esqueleto.tscn")
var inimigo2 : PackedScene = preload("res://cenas/cranio.tscn")
var inimigo3 : PackedScene = preload("res://cenas/vamp.tscn")
var inimigo4 : PackedScene = preload("res://cenas/esqueleto2.tscn")
var inimigo5 : PackedScene = preload ("res://cenas/slime.tscn")

var iscriador: bool = false

#todo: isso aqui é feito para manter a vez, depois tem que mudar essa merda
var isp2 : bool = false #0 para player 1 1 para player 2, se houver player 2 no jogo aguarda
var numero_jogadores: int = 1

func isvez () -> bool :
	#garantir que se tiver só um jogador o isp2 numca muda
	
	if numero_jogadores < 2:
		isp2 = false
		
	if current_state == GameState.PLAYER_TURN and isp2 == false:
		return true
	return false


# --- Pathfinding ---
var astar_grid = AStar2D.new()

# --- Estado do Jogo ---
enum GameState { PLAYER_TURN, ENEMY_TURN, PAUSED, FREE_ROAM }
var current_state: GameState = GameState.PAUSED

# --- Sinais ---
signal player_turn_started
signal enemy_turn_started


func inimigo_morreu (nome, node):
	print_debug("inimigo " + str(nome) + "morreu, node : " +str( node))

	
	
func is_p1_turn() -> bool:
	return !isp2;

func get_player ():
	player = get_tree().get_first_node_in_group("player")
	

func get_player2():
	player2 =  get_tree().get_first_node_in_group("player2")
	
	
func _ready():
	if !has_node("propagador"):
		Eventos.connect("popup",_on_pop_up )
		iscriador = true	
		start_game()
		return
		
		
	$propagador.dungeonmanager = self
	Eventos.connect("async_evento_recebido", async_evento_recebido)
	Eventos.connect("carregar",_on_carregar)	
	Eventos.connect("inimigo_morreu", inimigo_morreu)
	
	if Goblais.modo == "join":
		var event = {
			"type": "join",
			"source": Goblais.nome
		}
		$propagador.send_event(event)
	else:
		iscriador = true	
		start_game()
		$propagador.send_scene_state()
		
		
	



func join_p2 ():
	#
	#var spp2 = get_tree().get_nodes_in_group("spawn_player2")[0]
	#player2 = packedp2.instantiate()
	#player2.position = spp2.position
	print ("p2 entrou")
	
	#add_child(player2)
	numero_jogadores = 2
	isp2 = true
	
	#super porco
	
	#a linha em seguida pode criar um player 2 e sobreescrever me
	#$propagador.send_scene_state() 
	var event = {
		"type": "bemvindo",
		"source": Goblais.nome
	}
	$propagador.send_event(event)
	

	

	#player.action_taken.connect(_on_player_action_taken)	
	#nesse caso tem que ver como vai passar para o outro a vez
	

# para startar um jogo novo ! 
	



func _on_carregar () :
	get_player()
	get_player2()
	
	player.action_taken.connect(_on_player_action_taken)
	_create_astar_grid()
	
	for enemy in enemies_container.get_children():
		if enemy.has_method("set_turn_manager"):
			enemy.set_turn_manager(self)
			enemy.player_node = player
	
	current_state = GameState.PLAYER_TURN
	emit_signal("player_turn_started")	
	


func _on_player_action_taken():
	$anda.play()
	if current_state != GameState.PLAYER_TURN: return
	
	if _count_living_enemies() == 0:
		current_state = GameState.FREE_ROAM
		if player.has_method("set_can_act"): 
			Eventos.emit_signal("log", "Você venceu todos os inimigos")
			player.set_can_act(true)
		return
	
	if player.has_method("set_can_act"): player.set_can_act(false)
	current_state = GameState.ENEMY_TURN
	emit_signal("enemy_turn_started")
	#print("--- Turno dos Inimigos ---")
	var _unused = await _process_enemy_turns()

func _process_enemy_turns():
	#await get_tree().create_timer(0.5).timeout
	$UI/topo/turno/inimigo.visible = true
	var living_enemies = []
	for enemy in enemies_container.get_children():
		if is_instance_valid(enemy) and not (enemy.has_method("is_dead") and enemy.is_dead()):
			living_enemies.append(enemy)
			
	for enemy in living_enemies:
		if is_instance_valid(enemy) :
			if enemy.cooldown > 0:
				enemy.cooldown -= 1
				
			enemy.acoes_disponiveis = enemy.numero_acoes
			
			enemy.take_turn()
			await enemy.action_taken
		#	await get_tree().create_timer(0.3).timeout
	_end_enemy_turn_sequence()


func atualiza_mapa_geral() -> void:
	$propagador.send_scene_state()
	var event = {
		"type": "atualizarmapa",
		"source": Goblais.nome
	} 
	$propagador.send_event(event)	

func async_fim_turno():
	var event = {
			"type": "fimturnop",
			"source": Goblais.nome
		}
	$propagador.send_event(event)
		
		
func _end_enemy_turn_sequence():
	$UI/topo/turno/inimigo.visible = false
	await get_tree().create_timer(0.1).timeout
	for trap in get_tree().get_nodes_in_group("traps"):
		trap.cooldown -= 1
		if trap.cooldown < 0 : trap.cooldown = 0 
	if _count_living_enemies() == 0:
		current_state = GameState.FREE_ROAM
		if player.has_method("set_can_act"): player.set_can_act(true)
		Eventos.emit_signal("log", "todos os inimigos foram mortos")		
		#print_debug("Último inimigo derrotado! Mudando para o modo livre.")
		return

	if current_state == GameState.FREE_ROAM: return
		
	current_state = GameState.PLAYER_TURN
	
		
		#ele inverte de uma forma porca
	if numero_jogadores > 1:
		isp2 = !isp2
		
		
	if !isp2 :
		if player.has_method("set_can_act"): player.set_can_act(true)
		emit_signal("player_turn_started")
		#print("--- Turno do Jogador ---")
	else :
		#if player.has_method("set_can_act"): player.set_can_act(true)
		#todo: emitir sinal para o p2 via api
		#emit_signal("player_turn_started")
		#print("--- Turno do Jogador 2 ---")
		pass
		#async_fim_turno()
		#atualiza_mapa_geral()
		
		#todo: enviar que acabou o turno

func _count_living_enemies() -> int:
	var living_enemies = 0
	for enemy in enemies_container.get_children():
		if is_instance_valid(enemy) and (not enemy.has_method("is_dead") or not enemy.is_dead):
			living_enemies += 1
	return living_enemies

# --- Lógica de Pathfinding A* ---

func _create_astar_grid():
	astar_grid.clear()
	
	# Pega a posição de todas as portas para tratá-las como paredes inicialmente
	var door_cells = []
	for door in get_tree().get_nodes_in_group("portas"):
		door_cells.append(floor_tilemap.local_to_map(door.global_position))

	var used_cells = floor_tilemap.get_used_cells()

	for cell in used_cells:
		# Ignora células com paredes ou com portas fechadas
		if walls_tilemap.get_cell_source_id(cell) != -1 or cell in door_cells:
			continue
			
		var point_id = _get_point_id(cell)
		astar_grid.add_point(point_id, Vector2(cell))

	for point_id in astar_grid.get_point_ids():
		var cell = Vector2i(astar_grid.get_point_position(point_id))
		for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var neighbor_cell = cell + offset
			var neighbor_point_id = _get_point_id(neighbor_cell)
			if astar_grid.has_point(neighbor_point_id):
				astar_grid.connect_points(point_id, neighbor_point_id, false)
	
	#print_debug("A* Grid created with ", astar_grid.get_point_count(), " walkable points.")

func _get_point_id(cell: Vector2i) -> int:
	const OFFSET = 5000 
	return (cell.x + OFFSET) + (cell.y + OFFSET) * (OFFSET * 2)

func calculate_path(start_world_pos: Vector2, end_world_pos: Vector2) -> PackedVector2Array:
	var start_cell = floor_tilemap.local_to_map(start_world_pos)
	var end_cell = floor_tilemap.local_to_map(end_world_pos)
	#print_debug("Pathfinding: De %s (mundo) -> %s (mapa) para %s (mundo) -> %s (mapa)" % [start_world_pos, start_cell, end_world_pos, end_cell])
	
	var start_id = _get_point_id(start_cell)
	var end_id = _get_point_id(end_cell)
	
	if not astar_grid.has_point(start_id):
		print_debug("Pathfinding ERRO: Ponto de início %s (ID: %s) não existe na grade A*." % [start_cell, start_id])
		return PackedVector2Array()
	if not astar_grid.has_point(end_id):
		print_debug("Pathfinding ERRO: Ponto de destino %s (ID: %s) não existe na grade A*." % [end_cell, end_id])
		return PackedVector2Array()

	var path_ids = astar_grid.get_id_path(start_id, end_id)
	if path_ids.is_empty():
		print_debug("Pathfinding AVISO: A* não encontrou caminho entre ID %s e %s." % [start_id, end_id])

	var world_path = PackedVector2Array()
	for point_id in path_ids:
		var cell_pos_v2 = astar_grid.get_point_position(point_id)
		world_path.append(floor_tilemap.map_to_local(Vector2i(cell_pos_v2)))
		
	return world_path

func get_player_position() -> Vector2:
	if is_instance_valid(player):
		return player.global_position
	return Vector2.ZERO

func update_walkable_area(world_pos: Vector2):
	var cell = floor_tilemap.local_to_map(world_pos)
	var point_id = _get_point_id(cell)
	
	if not astar_grid.has_point(point_id):
		astar_grid.add_point(point_id, Vector2(cell))
	#	print_debug("A* Grid: Ponto adicionado em %s" % cell)
		
		# Conecta o novo ponto aos seus vizinhos
		for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var neighbor_cell = cell + offset
			var neighbor_point_id = _get_point_id(neighbor_cell)
			if astar_grid.has_point(neighbor_point_id):
				astar_grid.connect_points(point_id, neighbor_point_id, false)
				astar_grid.connect_points(neighbor_point_id, point_id, false)
	#			print_debug("A* Grid: Conectado a %s" % neighbor_cell)


func async_evento_recebido (event_data: Dictionary):
	
	if event_data.get("type") =="fimturnop":
	#	print ("fimturnop recebido")
		_on_player_action_taken()
		
	if event_data.get ("type") =="join":
		if event_data.get ("source") == Goblais.nome:
			#não é startgame
			#tart_game()
			print ("bemvindo")
			isp2 = true
			numero_jogadores = 2
			$propagador.fetch_scene_state()

		else:
			join_p2()
			
	#acho que tem um bug aqui
	if event_data.get ("type") == "atualizarmapa":
		if event_data.get ("source") != Goblais.nome:
			$propagador.fetch_scene_state()
		
	if event_data.get ("type") =="bemvindo":
		print ("bemvindo")
		$propagador.fetch_scene_state()
		get_player()
		






	
#para qunando conectar num jogo ja iniciado
func async_start():
	var spp2 = get_tree().get_nodes_in_group("spawn_player2")[0]
	
	player = packedp1.instantiate()
	player.position = spp2.position
	
	add_child(player)
	
	player.action_taken.connect(_on_player_action_taken)
	numero_jogadores = 2
	_on_player_action_taken()
	atualiza_mapa_geral()
	
	
	pass
func start_game():
	randomize()
	var p1  = get_tree().get_first_node_in_group("player")
	get_player2()
	
		
	
	
	
	
	var spp1 = get_tree().get_nodes_in_group("spawn_player1")[0]
	
	var spinimigos = get_tree().get_nodes_in_group("spawn_inimigos")
	
	player = packedp1.instantiate()
	player.position = spp1.position
	
	add_child(player)
	
	player.action_taken.connect(_on_player_action_taken)
	
	#spawna inimigos para a fase 
	if name != "town" : 
	
		var inimigospk: Array
		inimigospk.append(inimigo5)
		inimigospk.append(inimigo5)
		inimigospk.append(inimigo1)
		inimigospk.append(inimigo2)
		inimigospk.append(inimigo3)
		inimigospk.append(inimigo4)
		
		
		
		for n in nini :
			var inimigo = inimigospk.pick_random().instantiate()
			inimigo.position = get_tree().get_nodes_in_group("spawn_inimigos").pick_random().position
			

			$inimigos.add_child(inimigo)	
		
		_create_astar_grid()
		
		# waesta repetindo for
		for enemy in enemies_container.get_children():
			if enemy.has_method("set_turn_manager"):
				enemy.set_turn_manager(self)
				enemy.player_node = player

	current_state = GameState.PLAYER_TURN
	if player.has_method("set_can_act"):
		player.set_can_act(true)
	emit_signal("player_turn_started")
	#print("--- Turno do Jogador ---")


func _on_setup_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("clique_esquerdo"):
		get_tree().change_scene_to_file("res://cenas/main.tscn")
	

func _on_pop_up(texto):
	var popup = load("res://cenas/pup.tscn")
	
	popup = popup.instantiate()
	add_child(popup)
	popup.get_node("RichTextLabel2").text  = texto
