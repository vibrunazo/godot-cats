extends Control

class_name PauseMenu

func toogle():
	pause(!get_tree().paused)

func pause(new_paused: bool = true):
	if new_paused:
		get_tree().paused = new_paused
		$AnimationPlayer.stop()
		$AnimationPlayer.play("start")
		audio_fade_in()
		yield($TweenAudio,"tween_completed")
		$AudioPause.play()
	else:
		Global.set_volume(-80)
		$AnimationPlayer.stop()
		$AnimationPlayer.play("stop")
		audio_fade_in()
		get_tree().paused = new_paused
		
func slow_pause():
	audio_fade_out()
#	yield($TweenAudio,"tween_completed")
	yield(get_tree().create_timer(0.2), "timeout")
	pause(true)

func audio_fade_out():
	$TweenAudio.interpolate_method(self, "change_volume", Global.master_volume, -80, 0.5)
	$TweenAudio.start()
	yield($TweenAudio,"tween_completed")
#	Global.reset_volume()

func audio_fade_in():
	$TweenAudio.interpolate_method(self, "change_volume", -80, Global.master_volume, 0.3)
	$TweenAudio.start()

func change_volume(val):
	Global.set_volume(val)

func _on_ResumeButton_pressed():
	pause(false)

func _on_RestartButton_pressed():
	pause(false)
	get_tree().reload_current_scene()

func _on_ExitButton_pressed():
	pause(false)
	get_tree().change_scene("res://scenes/maps/MainScene.tscn")
