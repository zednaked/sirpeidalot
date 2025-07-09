# dungeon_generator.gd -> Conceptually the TurnManager
# This script manages the turn-based game flow and pathfinding.
# Attach this script to a root node in your main scene.

extends Node2D

# --- Constants ---
const TILE_SIZE = 16

# --- Node References (Set in the Inspector) ---
@export var player: CharacterBody2D
@export var enemies_container: Node
@export var floor_tilemap: TileMapLayer
@export var walls_tilemap: TileMapLayer

# --- Pathfinding ---
var astar_grid = AStar2D.new()

# --- Game State ---
enum GameState { PLAYER_TURN, ENEMY_TURN, PAUSED, FREE_ROAM }
var current_state: GameState = GameState.PAUSED

# --- Signals ---
signal player_turn_started
signal enemy_turn_started

func _ready():
	# Validations
	if not player: print_debug("Player not set in TurnManager."); return
	if not enemies_container: print_debug("Enemies container not set."); return
	if not floor_tilemap: print_debug("Floor TileMapLayer not set."); return
	if not walls_tilemap: print_debug("Walls TileMapLayer not set."); return

	if not player.has_signal("action_taken"):
		print_debug("Player node is missing the 'action_taken' signal.")
	else:
		player.connect("action_taken", _on_player_action_taken)

	call_deferred("start_game")

func start_game():
	print("Game has started!")
	
	_create_astar_grid()
	
	var enemies = enemies_container.get_children()
	for enemy in enemies:
		if enemy.has_method("set_turn_manager"):
			enemy.set_turn_manager(self)
		else:
			print_debug("Enemy %s is missing the 'set_turn_manager' method." % enemy.name)

	current_state = GameState.PLAYER_TURN
	if player.has_method("set_can_act"):
		player.set_can_act(true)
	emit_signal("player_turn_started")
	print("--- Player's Turn ---")

func _on_player_action_taken():
	if current_state != GameState.PLAYER_TURN:
		return

	# Check for win condition AFTER the player's action is resolved.
	if _count_living_enemies() == 0:
		print_debug("All enemies defeated! Switching to free roam mode.")
		current_state = GameState.FREE_ROAM
		if player.has_method("set_can_act"):
			player.set_can_act(true)
		return
	
	print("Player acted. Ending turn.")
	
	if player.has_method("set_can_act"):
		player.set_can_act(false)
		
	current_state = GameState.ENEMY_TURN
	emit_signal("enemy_turn_started")
	print("--- Enemies' Turn ---")
	
	call_deferred("_process_enemy_turns")

func _process_enemy_turns():
	var enemies = enemies_container.get_children().duplicate()

	for enemy in enemies:
		# Skip dead or invalid enemies
		if not is_instance_valid(enemy) or enemy.is_dead:
			continue

		enemy.take_turn()
		await enemy.action_taken
	
	_end_enemy_turn_sequence()

func _end_enemy_turn_sequence():
	# A check to see if the last enemy was killed during this turn sequence.
	if _count_living_enemies() == 0:
		current_state = GameState.FREE_ROAM
		if player.has_method("set_can_act"):
			player.set_can_act(true)
		print_debug("Last enemy defeated! Switching to free roam mode.")
		return

	if current_state == GameState.FREE_ROAM:
		return
		
	print("All enemies have acted. Ending turn.")
	
	current_state = GameState.PLAYER_TURN
	
	if player.has_method("set_can_act"):
		player.set_can_act(true)
		
	emit_signal("player_turn_started")
	print("--- Player's Turn ---")

# --- Custom Logic ---

func _count_living_enemies() -> int:
	var living_enemies = 0
	for enemy in enemies_container.get_children():
		if is_instance_valid(enemy) and not enemy.is_dead:
			living_enemies += 1
	return living_enemies

# --- A* Pathfinding Logic ---

func _create_astar_grid():
	astar_grid.clear()
	var used_rect = floor_tilemap.get_used_rect()

	for y in range(used_rect.position.y, used_rect.end.y):
		for x in range(used_rect.position.x, used_rect.end.x):
			var cell = Vector2i(x, y)
			var is_floor = floor_tilemap.get_cell_source_id(cell) != -1
			var is_wall = walls_tilemap.get_cell_source_id(cell) != -1
			
			if is_floor and not is_wall:
				var point_id = _get_point_id(cell)
				astar_grid.add_point(point_id, Vector2(cell))

	for y in range(used_rect.position.y, used_rect.end.y):
		for x in range(used_rect.position.x, used_rect.end.x):
			var cell = Vector2i(x, y)
			var current_point_id = _get_point_id(cell)
			
			if astar_grid.has_point(current_point_id):
				for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
					var neighbor_cell = cell + offset
					var neighbor_point_id = _get_point_id(neighbor_cell)
					
					if astar_grid.has_point(neighbor_point_id):
						astar_grid.connect_points(current_point_id, neighbor_point_id, false)

func _get_point_id(cell: Vector2i) -> int:
	const OFFSET = 5000 
	return (cell.x + OFFSET) + (cell.y + OFFSET) * (OFFSET * 2)

func calculate_path(start_world_pos: Vector2, end_world_pos: Vector2) -> PackedVector2Array:
	var start_cell = floor_tilemap.local_to_map(start_world_pos)
	var end_cell = floor_tilemap.local_to_map(end_world_pos)
	
	var start_id = _get_point_id(start_cell)
	var end_id = _get_point_id(end_cell)
	
	if not astar_grid.has_point(start_id) or not astar_grid.has_point(end_id):
		return PackedVector2Array()

	var path_ids = astar_grid.get_id_path(start_id, end_id)
	var world_path = PackedVector2Array()
	for point_id in path_ids:
		var cell_pos_v2 = astar_grid.get_point_position(point_id)
		world_path.append(floor_tilemap.map_to_local(Vector2i(cell_pos_v2)))
		
	return world_path

func get_player_position() -> Vector2:
	if is_instance_valid(player):
		return player.global_position
	return Vector2.ZERO
