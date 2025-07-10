# dungeon_generator.gd -> Gerenciador de Turnos e Estado do Jogo
# Este script orquestra o fluxo do jogo baseado em turnos, gerencia o estado
# geral e fornece serviços de pathfinding para os inimigos.

extends Node2D

# --- Referências de Nós (Configuradas no Editor) ---
@export var player: CharacterBody2D
@export var enemies_container: Node
@export var floor_tilemap: TileMapLayer  # Camada com os tiles de chão (andáveis)
@export var walls_tilemap: TileMapLayer  # Camada com paredes e obstáculos

# --- Pathfinding ---
var astar_grid = AStar2D.new()

# --- Estado do Jogo ---
enum GameState { PLAYER_TURN, ENEMY_TURN, PAUSED, FREE_ROAM }
var current_state: GameState = GameState.PAUSED

# --- Sinais ---
signal player_turn_started
signal enemy_turn_started

func _ready():
	# Validações
	if not player: print_debug("Player não configurado no TurnManager."); return
	if not enemies_container: print_debug("Container de inimigos não configurado."); return
	if not floor_tilemap: print_debug("TileMapLayer de chão não configurado."); return
	if not walls_tilemap: print_debug("TileMapLayer de paredes não configurado."); return

	if player.has_signal("action_taken"):
		player.action_taken.connect(_on_player_action_taken)
	else:
		print_debug("Nó do jogador não possui o sinal 'action_taken'.")

	call_deferred("start_game")
	add_to_group("turn_manager")

func start_game():
	print("O jogo começou!")
	_create_astar_grid()
	
	for enemy in enemies_container.get_children():
		if enemy.has_method("set_turn_manager"):
			enemy.set_turn_manager(self)

	current_state = GameState.PLAYER_TURN
	if player.has_method("set_can_act"):
		player.set_can_act(true)
	emit_signal("player_turn_started")
	print("--- Turno do Jogador ---")

func _on_player_action_taken():
	if current_state != GameState.PLAYER_TURN: return

	if _count_living_enemies() == 0:
		current_state = GameState.FREE_ROAM
		if player.has_method("set_can_act"): player.set_can_act(true)
		print_debug("Todos os inimigos derrotados! Mudando para o modo livre.")
		return
	
	if player.has_method("set_can_act"): player.set_can_act(false)
	current_state = GameState.ENEMY_TURN
	emit_signal("enemy_turn_started")
	print("--- Turno dos Inimigos ---")
	var _unused = await _process_enemy_turns()

func _process_enemy_turns():
	var living_enemies = []
	for enemy in enemies_container.get_children():
		if is_instance_valid(enemy) and not (enemy.has_method("is_dead") and enemy.is_dead()):
			living_enemies.append(enemy)
			
	for enemy in living_enemies:
		enemy.take_turn()
		await enemy.action_taken
	
	_end_enemy_turn_sequence()

func _end_enemy_turn_sequence():
	if _count_living_enemies() == 0:
		current_state = GameState.FREE_ROAM
		if player.has_method("set_can_act"): player.set_can_act(true)
		print_debug("Último inimigo derrotado! Mudando para o modo livre.")
		return

	if current_state == GameState.FREE_ROAM: return
		
	current_state = GameState.PLAYER_TURN
	if player.has_method("set_can_act"): player.set_can_act(true)
	emit_signal("player_turn_started")
	print("--- Turno do Jogador ---")

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
	
	print_debug("A* Grid created with ", astar_grid.get_point_count(), " walkable points.")

func _get_point_id(cell: Vector2i) -> int:
	const OFFSET = 5000 
	return (cell.x + OFFSET) + (cell.y + OFFSET) * (OFFSET * 2)

func calculate_path(start_world_pos: Vector2, end_world_pos: Vector2) -> PackedVector2Array:
	var start_cell = floor_tilemap.local_to_map(start_world_pos)
	var end_cell = floor_tilemap.local_to_map(end_world_pos)
	print_debug("Pathfinding: De %s (mundo) -> %s (mapa) para %s (mundo) -> %s (mapa)" % [start_world_pos, start_cell, end_world_pos, end_cell])
	
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
		print_debug("A* Grid: Ponto adicionado em %s" % cell)
		
		# Conecta o novo ponto aos seus vizinhos
		for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var neighbor_cell = cell + offset
			var neighbor_point_id = _get_point_id(neighbor_cell)
			if astar_grid.has_point(neighbor_point_id):
				astar_grid.connect_points(point_id, neighbor_point_id, false)
				astar_grid.connect_points(neighbor_point_id, point_id, false)
				print_debug("A* Grid: Conectado a %s" % neighbor_cell)
