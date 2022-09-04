extends PauseMenu

func _ready():
	$AnimationPlayer.play("start", 1, 0.2)

func _on_ResumeButton_pressed():
	pass
#	get_tree().change_scene("res://scenes/Map.tscn")
	
func _on_ExitButton_pressed():
	get_tree().quit()
