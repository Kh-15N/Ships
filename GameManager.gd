extends Node

@export var ship_scene: PackedScene

@rpc("authority", "call_local")
func create_ship(hex: HexMesh, type, team):
	print(hex, team)
	var ship: Ship = ship_scene.instantiate()
	ship.team = team
	# нужно будет сделать выбор типа
	print(ship)
	add_child(ship)
	ship.position = hex.position + Vector3.UP
	print(ship)


@rpc("any_peer", "call_local")
func request_create_ship(hex: HexMesh, type, team):
	if multiplayer.is_server():
		create_ship.rpc(hex, type, team)
