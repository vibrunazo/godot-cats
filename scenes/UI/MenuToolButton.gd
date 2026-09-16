extends Button

class_name MenuToolButton

#func _ready() -> void:
#	$AnimationPlayer.play("focus", -1, 1 / Engine.time_scale)


func _on_MenuToolButton_focus_entered() -> void:
	$AnimationPlayer.play("focus", -1, 1.0 / Engine.time_scale)


func _on_MenuToolButton_focus_exited() -> void:
	$AnimationPlayer.stop()
