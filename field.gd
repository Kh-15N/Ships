extends Node3D

@export 
var hex_scene: PackedScene

@export
var size: int = 10

func _enter_tree():
	gen_hex_field()

#@rpc("call_local")
func gen_hex_field():
	for x in range(size):
		for z in range(size):
			var hex: HexMesh = hex_scene.instantiate()
			hex.field_coordinates = Vector2(x, z)
			var hex_size = hex.mesh.get_aabb().size
			add_child(hex)
			hex.position = Vector3(
				(hex_size.x / 2) * (z % 2) - hex_size.x * x,
				0,
				(hex_size.z / 1.4) * z
			) 
const SPAWN_RANDOM := 5.0

func _ready():
	# We only need to spawn players on the server.
	if not multiplayer.is_server():
		return

	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(del_player)

	# Spawn already connected players
	for id in multiplayer.get_peers():
		add_player(id)

	# Spawn the local player unless this is a dedicated server export.
	if not OS.has_feature("dedicated_server"):
		add_player(1)


func _exit_tree():
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(del_player)


func add_player(id: int):
	var character = preload("res://cam_player.tscn").instantiate()
	# Set player id.
	character.player = id
	# Randomize character position.
	var pos := Vector2.from_angle(randf() * 2 * PI)
	character.position = Vector3(pos.x * SPAWN_RANDOM * randf(), 0, pos.y * SPAWN_RANDOM * randf())
	character.name = str(id)
	$Players.add_child(character, true)


func del_player(id: int):
	if not $Players.has_node(str(id)):
		return
	$Players.get_node(str(id)).queue_free()
	
@rpc("call_local", "any_peer")
func create_ship(pos, team):
	var ship: Ship = preload("res://ship.tscn").instantiate()
	add_child(ship)
	ship.position = pos + Vector3.UP
	#hex.is_ship_on_hex = true
	ship.team = team
