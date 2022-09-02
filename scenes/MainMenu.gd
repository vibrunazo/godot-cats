extends PauseMenu


func _on_ResumeButton_pressed():
	get_tree().change_scene("res://scenes/Map.tscn")
	
func _on_ExitButton_pressed():
	get_tree().quit()
