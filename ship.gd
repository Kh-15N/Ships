extends MeshInstance3D

class_name Ship



var hp = 10
var damage = 4
var movement_range = 4
var attack_range = 5

var team
var ready_to_move = true
var ready_to_fire = true


func _ready() -> void:
	$MultiplayerSynchronizer.is_node_ready()

func get_property_dict():
	var property_dict = {
	"hp": hp,
	"damage": damage,
	"movement_range": movement_range,
	"attack_range": attack_range,
	"team": team,
	"ready_to_move": ready_to_move,
	"ready_to_fire": ready_to_fire,
	}
	return property_dict
	


@rpc("call_local", "any_peer")
func move(new_position: Vector3):
	if not ready_to_move:
		return
	elif $"..".hex_size.x * movement_range < (position - new_position).length():
		return
	else:
		position = new_position
		ready_to_move = false

@rpc("any_peer", "call_local")
func set_team_color():
	print("set_color")
	#if multiplayer.get_remote_sender_id() != team:
		#return
	var team_index = $"..".players.find(team)
	print($"..".players," ",  multiplayer.get_remote_sender_id()," ",  team)
	for i in range(30):
		set_surface_override_material(i, $"..".team_colors[team_index])
