extends ToolButton

class_name MenuToolButton

#func _ready():
#	$AnimationPlayer.play("focus", -1, 1 / Engine.time_scale)


func _on_MenuToolButton_focus_entered():
	$AnimationPlayer.play("focus", -1, 1 / Engine.time_scale)


func _on_MenuToolButton_focus_exited():
	$AnimationPlayer.stop()
