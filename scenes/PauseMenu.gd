extends Control

class_name PauseMenu

func toogle():
	pause(!get_tree().paused)

func pause(new_paused: bool = true):
	get_tree().paused = new_paused
	if new_paused:
		$AnimationPlayer.stop()
		$AnimationPlayer.play("start")
	else:
		$AnimationPlayer.stop()
		$AnimationPlayer.play("stop")

func _on_ResumeButton_pressed():
	pause(false)

func _on_RestartButton_pressed():
	pause(false)
	get_tree().reload_current_scene()

func _on_ExitButton_pressed():
	pause(false)
	get_tree().change_scene("res://scenes/MainMenu.tscn")
