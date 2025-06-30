extends Node3D

var speed = 0.2
var rotation_speed = 0.02

var selected_hex = null
var selected_ship = null

# Called when the node enters the scene tree for the first time.
@export var player := 1 :
	set(id):
		player = id
		# Give authority over the player input to the appropriate peer.
		$MultiplayerSynchronizer.set_multiplayer_authority(id)



func _ready():
	# Set the camera as current if we are this player.
	if player == multiplayer.get_unique_id():
		$Node3D/Camera3D.current = true
	# Only process on server.
	# EDIT: Left the client simulate player movement too to compesate network latency.
	# set_physics_process(multiplayer.is_server())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move()
	rotate_player()
	if Input.is_action_just_pressed("click"):
		var raycast_result = ray_cast()
		if raycast_result.size() != 0:
			if raycast_result.collider.get_parent() is HexMesh:
				#print(raycast_result.collider.get_parent())
				selected_hex = raycast_result.collider.get_parent()
				selected_hex.got_clicked()
			if raycast_result.collider.get_parent() is Ship:
				selected_ship = raycast_result.collider.get_parent()
				
	if Input.is_action_just_pressed("move_or_attack"):
		if selected_ship != null and selected_hex != null:
			selected_ship.move.rpc(selected_hex.position)



func move():
	
	var input_dir: Vector2 = Vector2(
		Input.get_axis("move_left", "move_right"),
		 Input.get_axis("move_forward", "move_back")).normalized()
	var direction = Vector2(input_dir.x * cos(rotation.y) + sin(rotation.y) * input_dir.y, - input_dir.x * sin(rotation.y) + cos(rotation.y) * input_dir.y) 
	position += speed * Vector3(direction.x, -Input.get_axis("ui_up", "ui_down"), direction.y)

func rotate_player():
	rotate_y(Input.get_axis("rotation_right", "rotation_left") * rotation_speed)

func ray_cast():
	var ray_length = 1000
	var space_state = get_world_3d().direct_space_state
	var cam = $Node3D/Camera3D
	var mousepos = get_viewport().get_mouse_position()

	var origin = cam.project_ray_origin(mousepos)
	var end = origin + cam.project_ray_normal(mousepos) * ray_length
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true

	var result = space_state.intersect_ray(query)
	if result != { }:
		print(result.collider.get_parent())
	else:
		print("not hit")
	return result
	
	


func _on_battle_cruiser_pressed() -> void:
	if selected_hex != null:
		$".."/"..".create_ship.rpc(selected_hex.position, player)
