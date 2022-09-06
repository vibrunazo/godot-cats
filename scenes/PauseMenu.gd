extends Control

class_name PauseMenu

func toogle():
	pause(!get_tree().paused)

func pause(new_paused: bool = true):
	if new_paused:
		get_tree().paused = new_paused
		$AnimationPlayer.stop()
		$AnimationPlayer.play("start")
		audio_fade_out()
		$AudioStreamPlayer.play()
	else:
#		Global.set_volume(-80)
		$AnimationPlayer.stop()
		$AnimationPlayer.play("stop")
		audio_fade_in()
		get_tree().paused = new_paused
		
func slow_pause():
	audio_fade_out()
	yield(get_tree().create_timer(0.2), "timeout")
	get_tree().paused = true
	$AnimationPlayer.stop()
	$AnimationPlayer.play("start")
	$AudioStreamPlayer.play()

func audio_fade_out():
	Global.fade_out_game_volume()

func audio_fade_in():
	Global.fade_in_game_volume()

func change_volume(val):
	Global.set_volume(val)

func _on_ResumeButton_pressed():
	pause(false)

func _on_RestartButton_pressed():
	pause(false)
# warning-ignore:return_value_discarded
	get_tree().reload_current_scene()

func _on_ExitButton_pressed():
	pause(false)
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://scenes/maps/MainScene.tscn")
