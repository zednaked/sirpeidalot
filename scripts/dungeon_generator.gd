# dungeon_generator.gd -> Gerenciador de Turnos e Estado do Jogo
# Este script orquestra o fluxo do jogo baseado em turnos, gerencia o estado
# geral (turno do jogador, turno do inimigo, etc.) e fornece serviços de
# pathfinding para os inimigos. Ele deve ser anexado a um nó raiz na cena principal.

extends Node2D

# --- Constantes ---
const TILE_SIZE = 16

# --- Referências de Nós (Configuradas no Editor) ---
@export var player: CharacterBody2D          # Referência ao nó do jogador.
@export var enemies_container: Node         # Nó que contém todos os inimigos da cena.
@export var floor_tilemap: TileMapLayer     # TileMapLayer para o chão (usado no pathfinding).
@export var walls_tilemap: TileMapLayer     # TileMapLayer para as paredes (usado no pathfinding).

# --- Pathfinding ---
var astar_grid = AStar2D.new() # Objeto A* para cálculo de caminhos.

# --- Estado do Jogo ---
# Enum para os diferentes estados do jogo.
enum GameState { PLAYER_TURN, ENEMY_TURN, PAUSED, FREE_ROAM }
var current_state: GameState = GameState.PAUSED

# --- Sinais ---
signal player_turn_started # Emitido quando o turno do jogador começa.
signal enemy_turn_started  # Emitido quando o turno dos inimigos começa.

func _ready():
	# Validações para garantir que todas as referências foram configuradas no editor.
	if not player: print_debug("Player não configurado no TurnManager."); return
	if not enemies_container: print_debug("Container de inimigos não configurado."); return
	if not floor_tilemap: print_debug("TileMapLayer de chão não configurado."); return
	if not walls_tilemap: print_debug("TileMapLayer de paredes não configurado."); return

	# Conecta o sinal 'action_taken' do jogador à função correspondente.
	if not player.has_signal("action_taken"):
		print_debug("Nó do jogador não possui o sinal 'action_taken'.")
	else:
		player.connect("action_taken", _on_player_action_taken)

	# Adia a inicialização do jogo para o próximo frame.
	call_deferred("start_game")

# Inicia o jogo, cria o grid de pathfinding e define o estado inicial.
func start_game():
	print("O jogo começou!")
	
	_create_astar_grid()
	
	# Configura cada inimigo com uma referência a este TurnManager.
	var enemies = enemies_container.get_children()
	for enemy in enemies:
		if enemy.has_method("set_turn_manager"):
			enemy.set_turn_manager(self)
		else:
			print_debug("Inimigo %s não possui o método 'set_turn_manager'." % enemy.name)

	# Inicia o primeiro turno do jogador.
	current_state = GameState.PLAYER_TURN
	if player.has_method("set_can_act"):
		player.set_can_act(true)
	emit_signal("player_turn_started")
	print("--- Turno do Jogador ---")

# Chamado quando o jogador realiza uma ação que consome o turno.
func _on_player_action_taken():
	if current_state != GameState.PLAYER_TURN:
		return

	# Verifica a condição de vitória após a ação do jogador.
	if _count_living_enemies() == 0:
		print_debug("Todos os inimigos derrotados! Mudando para o modo livre.")
		current_state = GameState.FREE_ROAM
		if player.has_method("set_can_act"):
			player.set_can_act(true)
		return
	
	print("Jogador agiu. Finalizando turno.")
	
	# Desabilita a ação do jogador e inicia o turno dos inimigos.
	if player.has_method("set_can_act"):
		player.set_can_act(false)
		
	current_state = GameState.ENEMY_TURN
	emit_signal("enemy_turn_started")
	print("--- Turno dos Inimigos ---")
	
	call_deferred("_process_enemy_turns")

# Processa o turno de cada inimigo sequencialmente.
func _process_enemy_turns():
	var enemies = enemies_container.get_children().duplicate()

	for enemy in enemies:
		# Pula inimigos que já estão mortos ou inválidos.
		if not is_instance_valid(enemy) or enemy.is_dead:
			continue

		enemy.take_turn()
		await enemy.action_taken # Espera o inimigo completar sua ação.
	
	_end_enemy_turn_sequence()

# Finaliza a sequência de turnos dos inimigos e devolve o controle ao jogador.
func _end_enemy_turn_sequence():
	# Verifica se o último inimigo foi morto nesta sequência de turnos.
	if _count_living_enemies() == 0:
		current_state = GameState.FREE_ROAM
		if player.has_method("set_can_act"):
			player.set_can_act(true)
		print_debug("Último inimigo derrotado! Mudando para o modo livre.")
		return

	if current_state == GameState.FREE_ROAM:
		return
		
	print("Todos os inimigos agiram. Finalizando turno.")
	
	# Devolve o controle ao jogador.
	current_state = GameState.PLAYER_TURN
	
	if player.has_method("set_can_act"):
		player.set_can_act(true)
		
	emit_signal("player_turn_started")
	print("--- Turno do Jogador ---")

# --- Lógica Personalizada ---

# Conta quantos inimigos ainda estão vivos na cena.
func _count_living_enemies() -> int:
	var living_enemies = 0
	for enemy in enemies_container.get_children():
		if is_instance_valid(enemy) and not enemy.is_dead:
			living_enemies += 1
	return living_enemies

# --- Lógica de Pathfinding A* ---

# Cria o grid A* baseado nos tiles de chão e parede.
func _create_astar_grid():
	astar_grid.clear()
	var used_rect = floor_tilemap.get_used_rect()

	# Adiciona um ponto ao grid para cada tile de chão que não é uma parede.
	for y in range(used_rect.position.y, used_rect.end.y):
		for x in range(used_rect.position.x, used_rect.end.x):
			var cell = Vector2i(x, y)
			var is_floor = floor_tilemap.get_cell_source_id(cell) != -1
			var is_wall = walls_tilemap.get_cell_source_id(cell) != -1
			
			if is_floor and not is_wall:
				var point_id = _get_point_id(cell)
				astar_grid.add_point(point_id, Vector2(cell))

	# Conecta os pontos adjacentes no grid.
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

# Converte uma coordenada de célula (Vector2i) em um ID de ponto único (int).
func _get_point_id(cell: Vector2i) -> int:
	const OFFSET = 5000 
	return (cell.x + OFFSET) + (cell.y + OFFSET) * (OFFSET * 2)

# Calcula o caminho entre duas posições no mundo.
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

# Retorna a posição global atual do jogador.
func get_player_position() -> Vector2:
	if is_instance_valid(player):
		return player.global_position
	return Vector2.ZERO
