extends Node

#@export var server_url = "https://zednet.tail3f42c3.ts.net"

@export var server_url = "http://zednet:8000"

@export var propagatable_group = "propagaveis"

# Sinal para notificar outros scripts sobre eventos recebidos
signal event_received(event_data: Dictionary)

# Teremos dois nós HTTPRequest para evitar conflitos entre requisições
var http_nodes: HTTPRequest
var http_salas: HTTPRequest
var http_events: HTTPRequest

@onready var dungeonmanager : Node = get_parent()

func _ready():
	# Configura o HTTPRequest para o estado dos nós
	http_nodes = HTTPRequest.new()
	add_child(http_nodes)
	http_nodes.request_completed.connect(_on_nodes_request_completed)
	
	http_salas = HTTPRequest.new()
	add_child(http_salas)
	http_salas.request_completed.connect(_on_salas_request_completed)
	
	
	# Configura o HTTPRequest para os eventos
	http_events = HTTPRequest.new()
	add_child(http_events)
	http_events.request_completed.connect(_on_events_request_completed)


		

# ==================================================
#  SISTEMA DE ESTADO DE CENA (NÓS)
# ==================================================

# --- Envio de Estado ---


#ele sempre re-escreve
func send_scene_state():
	var nodes_to_propagate = get_tree().get_nodes_in_group(propagatable_group)
	var saladefault = 1
	var data = {"nodes": [],
				"salas" : [],
				"jogadores" : []
	}
	

	for node in nodes_to_propagate:
		#if not node is Node2D or node.scene_file_path.is_empty():
		#	continue
			
		var id
		var nomejogador
		
		if "is_dead" in node:
			id = node.is_dead
		
		#if "dono" in node:
	#		#é do tipo item
#			if node.dono != "":
				
			#	pass
		var dono
		
		if "dono" in node:
			dono = node.dono
			
		var path = node.scene_file_path
		
		if "nome" in node: #significa que é jogador de mp
			nomejogador = node.nomejogador
		
		if "player" in node:
			nomejogador = Goblais.nome
		
		var iscriador = dungeonmanager.iscriador
		
		var isvez = !dungeonmanager.isp2
		var isequipado
		
		if "isequipado" in node:
			isequipado = node.isequipado
				
		
		
		
		#todo ver se a vez é desse camarada ou não
		
		var node_data = {
			"name": node.name,
			"scene_path": path,
			"parent_path": node.get_parent().get_path(),
			"pos_x": node.position.x, "pos_y": node.position.y,
			"rotation": node.rotation,
			"scale_x": node.scale.x, "scale_y": node.scale.y,
			"is_dead": id,
			"nomejogador": nomejogador,
			"iscriador": iscriador,
			"isvez": isvez,
			"dono":dono,
			"sala": saladefault, #todo: mudar isso pelo valor real em principio sera so sala 1
			"isequipado": isequipado
		}
		
		
		data["nodes"].append(node_data)
		
		#fazendo para cada node
		var path2 = "res://cenas/_main.tscn"
		var salas_data = {
			"scene_path": path2,
			"nomep1": "zed",
			"nomep2": "teste1"
		}
		data["salas"].append(salas_data)
		
		var jogadores = {
			"nomejogador":"zed",
			"item1":"item1",	
		}
		



	var body = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	http_nodes.request(server_url + "/nodes", headers, HTTPClient.METHOD_POST, body)
	
	#precisa injetar aqui o conteudo que ja existe para não apagar outras salas PORCO
	

	
	
	
	
	#fazer o mesmo para salas e jogadores 
	

# --- Recebimento e Reconstrução de Estado ---
func fetch_scene_state():
	http_nodes.request(server_url + "/nodes", [], HTTPClient.METHOD_GET)

#todo, enxertar aqui um sistema de salas e jogadores por sala
#precisa 
func fetch_jogadores():
	http_salas.request(server_url + "/nodes", [], HTTPClient.METHOD_GET)
	pass
	
func fetch_vez ():
	http_salas.request(server_url + "/nodes", [], HTTPClient.METHOD_GET)
	
	
func _on_salas_request_completed (result,response_code, headers, body):
	if response_code != 200:
		print("ERRO na requisição de nós: ", response_code)
		return

	var json = JSON.parse_string(body.get_string_from_utf8()) #utf8 nao tem ç e ã todo: mudar isso
	
	
	
	var server_nodes = {}
	#só pra facilitar usar o name da node como index 
	for node_data in json["nodes"]:
		#print (node_data)
		server_nodes[node_data["name"]] = node_data
		
	if "isvez" in  server_nodes:
		if server_nodes.is_vez:
			if server_nodes.nomejogador == Goblais.nome:
				print ("sua vez")
			
	#------------------------------------------------
	
	
	#jeito porco de deixar uma parte so para a abertura
	
	if get_node("../Panel/salas"):
		$"../Panel/salas".clear()
		var _numero_jogadores = 0
		for node_name in server_nodes:
			var data = server_nodes[node_name]
			if data["nomejogador"]:
				_numero_jogadores += 1
				$"../Panel/salas".add_item(data["nomejogador"])	
	
		#dungeonmanager.numero_jogadores = _numero_jogadores
		
func _on_nodes_request_completed(result, response_code, headers, body):
	if response_code != 200:
		print("ERRO na requisição de nós: ", response_code)
		return

	var json = JSON.parse_string(body.get_string_from_utf8()) #utf8 nao tem ç e ã todo: mudar isso
	
	if json and json.has("nodes"):
		_reconstruct_scene(json["nodes"])

func _reconstruct_scene(nodes_data_from_server: Array):
	print("Iniciando reconstrução inteligente da cena...")
	
	# 1. Mapear nós existentes na cena pelo nome
	var teachou = 0 
	var vezde
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
			
			
				
				
			if "dono" in node:
				if "isequipado" in node:
					if node.isequipado != data["isequipado"]:
						node.isequipado = data["isequipado"]
						changed = true
					
				if node.dono != data["dono"]:
					node.dono = data["dono"]
					changed = true
					
			if data["isvez"]:
				if data["nomejogador"]:
					print ("é vez de " + data["nomejogador"])
					if data["nomejogador"] == Goblais.nome:
						dungeonmanager.isp2 = true
						print ("é sua vez !")

					
				
					
			#significa que é um inimnigo tem que fazer os procedimentos de _die
			
			if "is_dead" in node:
				if node.is_dead != data["is_dead"]:
					
					#adicionar o drop todo:
					
					#node.drop = "res://cenas/drop2.tscn"
					
					
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
			
			if "dono" in node:
				if node.dono == Goblais.nome:
					#todo
					if node.isequipado :
						node.reparent ($"../UI/inventario/equipado")
					else:
						node.reparent ($"../UI/inventario/mochila")
						
					node.position = Vector2(0,0)
				
			if changed:
				print_debug("Nó " + node_name  + " atualizado.")
		else:
			# NÓ NÃO EXISTE: Cria um novo
			print_debug("Criando novo nó: "+ node_name)
			var scene = load(data["scene_path"])
			var nome = data ["name"]
			
			
			#todo : aqui precisa ter um lugar que salva quem é o p1 e uqem é o p2
			if data["nomejogador"]:
				scene = load ("res://cenas/player2.tscn")
				
			if data["nomejogador"]	== Goblais.nome:
				teachou = true
				scene = load ("res://cenas/Jogador.tscn")
				
				

			
			
			if scene:
				
				

					
				var instance = scene.instantiate()
				
				if "nomejogador"  in instance:
					if data["nomejogador"] != "":
						instance.nomejogador = data["nomejogador"]
						
				if data["nomejogador"]	== Goblais.nome:
					dungeonmanager.player = instance
				
				
					
				
				instance.name = nome
				instance.position = Vector2(data["pos_x"], data["pos_y"])
				instance.rotation = data["rotation"]
				
				if data["is_dead"] == true :
					if instance.isinimigo:
						instance._die_async()
				
				if data["isvez"] :
					if data["nomejogador"]  == Goblais.nome:
						dungeonmanager.isp2 = false
						print ("é sua vez")
				
				
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
	
	if teachou:
		Eventos.emit_signal("carregar")
	else:
		print ("não te achou")
		#roda um spawna vc e salva !
	
		dungeonmanager.async_start()
	


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
			Eventos.emit_signal("async_evento_recebido", event_data)


func _on_timer_timeout() -> void:
	fetch_events()
	
	#fetch_scene_state()
	
	
