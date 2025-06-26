extends MeshInstance3D

class_name HexMesh

var field_coordinates: Vector2
static var currently_selected: HexMesh

var srart_pos = self.position

@export
var material_for_selected: Material

var is_ship_on_hex = false

func _enter_tree():
	reset_selection()
	
	

func reset_selection():
	set_surface_override_material(1, get_active_material(0))

@rpc("call_local", "any_peer")
func got_clicked():
	if currently_selected:
		currently_selected.reset_selection()
	currently_selected = self
	set_surface_override_material(1, material_for_selected)
