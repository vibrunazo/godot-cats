extends Control

class_name PauseMenu

## Name of the button that receives focus when the menu opens.
@export var focus_name: String = 'ResumeButton'


## Grabs focus for the default button so keyboard/gamepad works.
func set_focus() -> void:
	var button: Button = get_node("HBoxContainer/%s" % focus_name)
	button.grab_focus()
	print('focused on %s, name is %s' % [button.name, focus_name])


func toogle() -> void:
	pause(!get_tree().paused)


func pause(new_paused: bool = true) -> void:
	if new_paused:
		get_tree().paused = new_paused
		$AnimationPlayer.stop()
		$AnimationPlayer.play("start")
		audio_fade_out()
		$AudioStreamPlayer.play()
		set_focus()
	else:
#		Global.set_volume(-80)
		$AnimationPlayer.stop()
		$AnimationPlayer.play("stop")
		audio_fade_in()
		get_tree().paused = new_paused


func slow_pause() -> void:
	audio_fade_out()
	await get_tree().create_timer(0.2).timeout
	get_tree().paused = true
	$AnimationPlayer.stop()
	$AnimationPlayer.play("start")
	$AudioStreamPlayer.play()
	set_focus()


func audio_fade_out() -> void:
	Global.fade_out_game_volume()


func audio_fade_in() -> void:
	Global.fade_in_game_volume()


func change_volume(val: float) -> void:
	Global.set_volume(val)


func _on_ResumeButton_pressed() -> void:
	pause(false)


func _on_RestartButton_pressed() -> void:
	pause(false)
	get_tree().reload_current_scene()


func _on_ExitButton_pressed() -> void:
	pause(false)
	get_tree().change_scene_to_file("res://scenes/maps/MainScene.tscn")
