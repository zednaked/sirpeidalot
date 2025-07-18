extends Node

@export var server_url = "http://127.0.0.1:8000"
@export var propagatable_group = "propagaveis"

# Sinal para notificar outros scripts sobre eventos recebidos
signal event_received(event_data: Dictionary)

# Teremos dois nós HTTPRequest para evitar conflitos entre requisições
var http_nodes: HTTPRequest
var http_events: HTTPRequest

func _ready():
	# Configura o HTTPRequest para o estado dos nós
	http_nodes = HTTPRequest.new()
	add_child(http_nodes)
	http_nodes.request_completed.connect(_on_nodes_request_completed)
	
	# Configura o HTTPRequest para os eventos
	http_events = HTTPRequest.new()
	add_child(http_events)
	http_events.request_completed.connect(_on_events_request_completed)

# --- Funções de Teste ---

func _process(delta):
	# Pressione Enter/Espaço para ENVIAR o estado da cena
	if Input.is_action_just_pressed("ui_page_up"):
		print_debug("teste")
		print("--- Enviando estado da cena ---")
		send_scene_state()
	
	# Pressione Escape para BUSCAR o estado da cena
	if Input.is_action_just_pressed("ui_page_down"):
		print("--- Buscando estado da cena ---")
		fetch_scene_state()

	# Pressione a tecla 'A' para simular um evento de ataque
	if Input.is_action_just_pressed("ui_end"):
		print("--- Enviando evento de ataque ---")
		var event = {
			"type": "attack",
			"source": "Player", # Em um jogo real, seria o nome do nó
			"target": "Skeleton_1",
			"damage": 10
		}
		send_event(event)

	# Pressione a tecla 'T' para buscar eventos
	if Input.is_action_just_pressed("ui_text_submit"):
		print("--- Buscando eventos ---")
		fetch_events()

# ==================================================
#  SISTEMA DE ESTADO DE CENA (NÓS)
# ==================================================

# --- Envio de Estado ---
func send_scene_state():
	var nodes_to_propagate = get_tree().get_nodes_in_group(propagatable_group)
	var data = {"nodes": []}

	for node in nodes_to_propagate:
		if not node is Node2D or node.scene_file_path.is_empty():
			continue
			
		var id
		var nomejogador
		
		if "is_dead" in node:
			id = node.is_dead
		
		var path = node.scene_file_path
		
		if "nome" in node: #significa que é jogador de mp
			print_debug("um mp")
			nomejogador = node.nome
			
		if node.name == "player" : #sabemos que é um jogador
			print_debug("um jogador")
			nomejogador = Goblais.nome
		
		
		var node_data = {
			"name": node.name,
			"scene_path": path,
			"parent_path": node.get_parent().get_path(),
			"pos_x": node.position.x, "pos_y": node.position.y,
			"rotation": node.rotation,
			"scale_x": node.scale.x, "scale_y": node.scale.y,
			"is_dead": id,
			"nomejogador": nomejogador
		}
		data["nodes"].append(node_data)

	var body = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	http_nodes.request(server_url + "/nodes", headers, HTTPClient.METHOD_POST, body)

# --- Recebimento e Reconstrução de Estado ---
func fetch_scene_state():
	http_nodes.request(server_url + "/nodes", [], HTTPClient.METHOD_GET)

func _on_nodes_request_completed(result, response_code, headers, body):
	if response_code != 200:
		print("ERRO na requisição de nós: ", response_code)
		return

	var json = JSON.parse_string(body.get_string_from_utf8())
	if json and json.has("nodes"):
		_reconstruct_scene(json["nodes"])

func _reconstruct_scene(nodes_data_from_server: Array):
	print("Iniciando reconstrução inteligente da cena...")
	
	# 1. Mapear nós existentes na cena pelo nome
	var p1
	var existing_nodes = {}
	for node in get_tree().get_nodes_in_group(propagatable_group):
		existing_nodes[node.name] = node

	# 2. Mapear nós recebidos do servidor pelo nome
	var server_nodes = {}
	for node_data in nodes_data_from_server:
		server_nodes[node_data["name"]] = node_data

	# 3. Atualizar e criar nós
	for node_name in server_nodes:
		var data = server_nodes[node_name]
		if existing_nodes.has(node_name):
			# NÓ EXISTE: Compara e atualiza se necessário
			var node = existing_nodes[node_name]
			var changed = false
			
			#significa que é um inimnigo tem que fazer os procedimentos de _die
			if "is_dead" in node:
				if node.is_dead != data["is_dead"]:
					
					
					
					if data["is_dead"]:
						node._die_async()
					else:
						node.is_dead = false
						
					changed = true
				
			if not is_equal_approx(node.position.x, data["pos_x"]) or \
			   not is_equal_approx(node.position.y, data["pos_y"]):
				node.position = Vector2(data["pos_x"], data["pos_y"])
				changed = true
			if not is_equal_approx(node.rotation, data["rotation"]):
				node.rotation = data["rotation"]
				changed = true
			# Adicione mais comparações se necessário (escala, etc.)
			if changed:
				print_debug("Nó " + node_name  + " atualizado.")
		else:
			# NÓ NÃO EXISTE: Cria um novo
			print_debug("Criando novo nó: "+ node_name)
			var scene = load(data["scene_path"])
			var nome = data ["name"]
			
			if data["nomejogador"] != Goblais.nome: #significa que ão é o jogador e deve usar a cena de player
				
				scene = load ("res://cenas/player2.tscn")
				p1 = 0
			if data["nomejogador"] == Goblais.nome:
				p1 = 1
				scene = load("res://cenas/Jogador.tscn")
					
				
			
			if scene:
				var instance = scene.instantiate()
				
				instance.name = nome
				instance.position = Vector2(data["pos_x"], data["pos_y"])
				instance.rotation = data["rotation"]
				# Adicione outras propriedades aqui
				if p1 == 1:
					get_parent().player =  instance
					print_debug("jogador encontrado")
					get_parent().start_game()
					
				
				var parent = get_node(data["parent_path"])
				if parent:
					parent.add_child(instance)
					instance.add_to_group(propagatable_group)
				else:
					print_debug("ERRO: Pai não encontrado em " + data + " para o nó " + node_name)
					instance.queue_free() # Limpa a instância órfã
			else:
				print("ERRO: Falha ao carregar cena de '{data[]}'")

	# 4. Deletar nós que não existem mais no servidor
	for node_name in existing_nodes:
		if not server_nodes.has(node_name):
			print("Deletando nó obsoleto:" + node_name )
			existing_nodes[node_name].queue_free()

	print("Reconstrução inteligente concluída.")
	
	


# ==================================================
#  SISTEMA DE EVENTOS / MENSAGENS
# ==================================================

func send_event(event_data: Dictionary):
	var body = JSON.stringify(event_data)
	var headers = ["Content-Type: application/json"]
	http_events.request(server_url + "/events", headers, HTTPClient.METHOD_POST, body)

func fetch_events():
	http_events.request(server_url + "/events", [], HTTPClient.METHOD_GET)

func _on_events_request_completed(result, response_code, headers, body):
	if response_code != 200:
		print("ERRO na requisição de eventos: " + response_code)
		return

	var events = JSON.parse_string(body.get_string_from_utf8())
	if events and events is Array:
		for event_data in events:
			#print_debug ("Evento recebido: " + event_data)
			# Emite o sinal para que outros scripts possam reagir
			emit_signal("event_received", event_data)
