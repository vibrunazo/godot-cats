extends TextureButton

class_name CircleButton


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	print('circle ready')
	pass # Replace with function body.

func _set(property: String, value) -> bool:
	if property == "disabled":
		print('disabled is now %s' % value)
		if disabled != value:
			disabled = value
			if disabled:
				$AnimationPlayer.play("disabled")
			else:
				$AnimationPlayer.play("enabled")
#		apply_changes()
		return true
	return false

func _on_CircleButton_button_down():
	pass # Replace with function body.

func _on_CircleButton_button_up():
	pass # Replace with function body.

func _on_CircleButton_pressed():
	$AnimationPlayer.play("pressed")
	yield($AnimationPlayer,"animation_finished")
	if disabled:
		$AnimationPlayer.play("disabled")
