extends Control

class_name PauseMenu

func toogle():
	pause(!get_tree().paused)

func pause(new_paused: bool):
	get_tree().paused = new_paused
	visible = new_paused

func _on_ResumeButton_pressed():
	pause(false)

func _on_RestartButton_pressed():
	pause(false)
	get_tree().reload_current_scene()

func _on_ExitButton_pressed():
	get_tree().quit()
