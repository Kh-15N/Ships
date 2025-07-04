extends CharacterBody3D

@onready var camera= $Camera3D
@onready var label = $CanvasLayer/ActionPanel/MarginContainer/VBoxContainer/Label

const SPEED = 20.0

var selected_hex = null
var selected_ship = null
var ship_types = ["destroer", "cruiser", "battle_cruiser", "battle_ship"]

var alt = false
var raycast_permition = true

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())


func _ready() -> void:
	if not is_multiplayer_authority(): return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	camera.current = true

func _unhandled_input(event: InputEvent) -> void:
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		if not is_multiplayer_authority(): return
	if event is InputEventMouseMotion:
		if alt:
			rotate_y(-event.relative.x * .005)
			camera.rotate_x(-event.relative.y * .005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func _physics_process(delta: float) -> void:
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		if not is_multiplayer_authority(): return
	
	if Input.is_action_just_pressed("Alt"):
		alt = (int(alt) + 1) % 2
		if alt:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		

	if Input.is_action_just_pressed("click") and raycast_permition:
		var raycast_result = ray_cast()
		if raycast_result.size() != 0:
			if raycast_result.collider.get_parent() is HexMesh:
				#print(raycast_result.collider.get_parent())
				selected_hex = raycast_result.collider.get_parent()
				selected_hex.got_clicked()
				selected_ship = null
			if raycast_result.collider.get_parent().get_parent() is Ship:
				selected_ship = raycast_result.collider.get_parent().get_parent()
	if Input.is_action_just_pressed("move_or_attack"):
		if selected_ship != null:
			var raycast_result = ray_cast()
			if raycast_result.size() != 0:
				if raycast_result.collider.get_parent() is HexMesh:
					#print(raycast_result.collider.get_parent())
					selected_hex = raycast_result.collider.get_parent()
					selected_hex.got_clicked()
					var ship_index = $"..".ships.find(selected_ship)
					$"..".move_ship.rpc(ship_index, selected_hex.get_index_in_hex_list())
				if raycast_result.collider.get_parent().get_parrent() is Ship:
					var attacker_index = $"..".ships.find(selected_ship)
					var targert_index = $"..".ships.find(raycast_result.collider.get_parent().get_parrent())
					$"..".attack.rpc(attacker_index, targert_index)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, -Input.get_axis("ui_up", "ui_down"), input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		velocity.y = direction.y * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)

	move_and_slide()

func ray_cast():
	var ray_length = 1000
	var space_state = get_world_3d().direct_space_state
	var mousepos = get_viewport().get_mouse_position()

	var origin = camera.project_ray_origin(mousepos)
	var end = origin + camera.project_ray_normal(mousepos) * ray_length
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true

	var result = space_state.intersect_ray(query)
	if result != { }:
		if result.collider.get_parent() is Ship:
			print(result.collider.get_parent(), " ", result.collider.get_parent().hp, " ", result.collider.get_parent().team)
		else: print(result.collider.get_parent())
	else:
		print("not hit")
	return result




func _on_option_button_item_selected(index: int) -> void:
	if selected_hex != null:
		if index != 0:
			var type = transform_index_to_type(index - 1)
			$"..".request_create_ship.rpc_id(1, $"..".hex_list.find(selected_hex), type, str(name).to_int())
	$CanvasLayer/ActionPanel/MarginContainer/VBoxContainer/OptionButton.selected = 0

func transform_index_to_type(index: int):
	return ship_types[index]


func _on_action_panel_mouse_entered() -> void:
	raycast_permition = false


func _on_action_panel_mouse_exited() -> void:
	if not $CanvasLayer/ActionPanel.get_global_rect().has_point(get_viewport().get_mouse_position()):
		raycast_permition = true

	


func _on_button_pressed() -> void:
	$"..".end_turn.rpc()
