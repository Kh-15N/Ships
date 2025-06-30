extends PanelContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in get_children():
		if child is Control:
			child.focus_mode = Control.FOCUS_NONE
	if not is_multiplayer_authority(): get_parent().visible = false
