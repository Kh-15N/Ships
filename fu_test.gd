extends Node

@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddeessEntry
@onready var turn_label = $CanvasLayer/TurnCounter/MarginContainer/VBoxContainer/TurnLabel

@export var color_1: StandardMaterial3D
@export var color_2: StandardMaterial3D
@export var hex_scene: PackedScene
@export var ship_scene: PackedScene
@export var size: int = 10

var team_colors: Array[StandardMaterial3D] = [
	preload("res://green.tres"),
	preload("res://water.tres") # Динамически созданный материал
]
var hex_list = []
var ships = []
var players = []
var turn = 0 # индекс игрока в players
var hex_size

const Player = preload("res://player.tscn")
const PORT = 8080
var enet_peer = ENetMultiplayerPeer.new()

var game_started = false

func _enter_tree() -> void:
	gen_hex_field()
	

func  _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func gen_hex_field():
	for x in range(size):
		for z in range(size):
			var hex: HexMesh = hex_scene.instantiate()
			hex.field_coordinates = Vector2(x, z)
			hex_size = hex.mesh.get_aabb().size
			hex_list.append(hex)
			hex.set_index_in_hex_list(hex_list.size() - 1)
			add_child(hex)
			hex.position = Vector3(
				(hex_size.x / 2) * (z % 2) - hex_size.x * x,
				0,
				(hex_size.z / 1.4) * z
			) 

#func _on_host_button_pressed() -> void:
	#main_menu.hide()
	#enet_peer.create_server(PORT)
	#multiplayer.multiplayer_peer = enet_peer
	#multiplayer.peer_connected.connect(add_player.rpc)
	#multiplayer.peer_connected.disconnect(remove_player)
	#add_player(multiplayer.get_unique_id())
	#
	

func _on_join_button_pressed() -> void:
	main_menu.hide()
	enet_peer.create_client(address_entry.text, PORT)
	multiplayer.multiplayer_peer = enet_peer

@rpc("authority", "call_local")
func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	players.append(peer_id)
	add_child(player)
	player.position = $Players.position
	if multiplayer.get_unique_id() == peer_id:
		spawn_objects_request.rpc_id(1, peer_id)

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

@rpc("any_peer", "call_remote")
func spawn_objects_request(self_id):
	if multiplayer.is_server():
		print("spawn_objects_request on server")
	spawn_objects(self_id)

@rpc("authority", "call_remote")
func spawn_objects(id):
	tell_about_players.rpc_id(id, players)
	for ship in ships:
		replikate_ship.rpc_id(id, ship.get_property_dict(), ship.transform)
	
	
@rpc("authority", "call_local")
func create_ship(hex_index, type, team):
	if game_started and players[turn] != team: # можно создавать корабли в процессе игры
		return
	var ship: Ship = ship_scene.instantiate()
	ships.append(ship)
	ship.team = team
	# нужно будет сделать выбор типа
	add_child(ship)
	ship.set_team_color.rpc()
	ship.position = hex_list[hex_index].position + Vector3.UP / 8
	

@rpc("authority", "call_remote")
func replikate_ship(ship_image_properties: Dictionary, ship_image_transform):
	var ship: Ship = ship_scene.instantiate()
	ships.append(ship)
	ship.hp = ship_image_properties["hp"]
	ship.damage = ship_image_properties["damage"]
	ship.movement_range = ship_image_properties["movement_range"]
	ship.attack_range = ship_image_properties["attack_range"]
	ship.team = ship_image_properties["team"]
	ship.ready_to_move = ship_image_properties["ready_to_move"]
	ship.ready_to_fire = ship_image_properties["ready_to_fire"]
	ship.transform = ship_image_transform
	add_child(ship)
	ship.set_team_color.rpc()

@rpc("authority", "call_remote")
func tell_about_players(spawned_players):
	players = spawned_players
	# Нужно ли это? 
	## вот тут костыль, нужен персонаж игрока, а он спавнится воследним
	#get_children()[-1].label.material = team_colors[players.find(str(name).to_int())] 
	#print(get_children()[-1].label)
	##CanvasLayer/ActionPanel/MarginContainer/VBoxContainer/Label

@rpc("any_peer", "call_local")
func move_ship(ship_index, hex_index):
	if game_started and multiplayer.get_remote_sender_id() != players[turn]:
		return
	if multiplayer.get_remote_sender_id() != ships[ship_index].team:
		return
	ships[ship_index].move(hex_list[hex_index].position)

@rpc("any_peer", "call_local")
func attack(attacker_index, target_index):
	if game_started and multiplayer.get_remote_sender_id() != players[turn]:
		return
	var attacker = ships[attacker_index]
	var target = ships[target_index]
	if multiplayer.get_remote_sender_id() != attacker.team:
		return
	if attacker.team == target.team:
		print("По своим стреляешь!")
		return
	if attacker.ready_to_fire: #добавь проверку дальности
		play_sound_of_shot()
		target.hp -= attacker.damage
		attacker.ready_to_fire = false
		if target.hp <= 0:
			destroy_ship(target_index)

@rpc("any_peer", "call_local")
func destroy_ship(ship_index):
	print(ships[ship_index])
	var ship = ships.pop_at(ship_index)
	ship.queue_free()
	print("target destroed ", multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_local")
func start_game():
	$CanvasLayer/TurnCounter/MarginContainer/VBoxContainer/Button.visible = false
	$CanvasLayer/TurnCounter/MarginContainer/VBoxContainer/Label.visible = true
	turn_label.text = str(players[turn])
	turn_label.visible = true
	game_started = true
	turn = 0

@rpc("any_peer", "call_local")
func end_turn():
	if game_started and multiplayer.get_remote_sender_id() != players[turn]:
		return
	turn = (turn + 1) % len(players)
	turn_label.text = str(players[turn])
	for ship in ships:
		ship.ready_to_fire = true
		ship.ready_to_move = true


func _on_button_pressed() -> void:
	start_game.rpc()

func play_sound_of_shot():
	var sound = AudioStreamPlayer.new()
	sound.stream = load("res://sounds/sound_of_shot(metal_pipe_sound).mp3")
	add_child(sound)
	sound.play()
