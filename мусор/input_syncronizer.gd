extends MultiplayerSynchronizer


func _ready():
	# Only process for the local player
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())

#@rpc("call_local")
#func click_on_hex():
	#if $"..".selected_hex != null:
		#$"..".selected_hex.got_clicked()
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#if Input.is_action_just_pressed("click"):
		#click_on_hex.rpc()
