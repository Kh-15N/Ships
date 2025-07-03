extends Node3D

class_name Ship

var hp
var damage
var movement_range
var attack_range
var model_path

var team
var ready_to_move = true
var ready_to_fire = true
var hex_under_ship = null # номер гекса в hex_list у главной сцены



func setup(data: Dictionary):
	hp = data.get("hp")
	damage = data.get("damage")
	movement_range = data.get("movement_range")
	attack_range = data.get("attack_range")
	model_path = data.get("model_path")
	var model = load(model_path).instantiate()
	add_child(model)


func get_property_dict():
	var property_dict = {
	"hp": hp,
	"damage": damage,
	"movement_range": movement_range,
	"attack_range": attack_range,
	"team": team,
	"ready_to_move": ready_to_move,
	"ready_to_fire": ready_to_fire,
	"hex_under_ship": hex_under_ship,
	"model_path": model_path
	}
	return property_dict
	
@rpc("call_local", "any_peer")
func move(new_position: Vector3):
	if not ready_to_move:
		return
	elif $"..".hex_size.x * movement_range < (position - new_position).length():
		return
	else:
		look_at(new_position)
		rotation.x = 0
		position = new_position + Vector3.UP / 8
		ready_to_move = false

@rpc("any_peer", "call_local")
func set_team_color():
	var team_index = $"..".players.find(team)
	for i in range(30):
		get_children()[1].set_surface_override_material(i, $"..".team_colors[team_index])
