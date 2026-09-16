extends PauseMenu


func _ready() -> void:
	$AnimationPlayer.play("start", 1, 0.2)


func _on_ResumeButton_pressed() -> void:
	pass
#	get_tree().change_scene("res://scenes/Map.tscn")

func _on_ExitButton_pressed() -> void:
	get_tree().quit()
