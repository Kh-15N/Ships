extends Control




func _on_create_ship_pressed() -> void:
	$Ships/BattleCruiser.visible = true


func _on_battle_cruiser_pressed() -> void:
	$Ships/BattleCruiser.visible = false
