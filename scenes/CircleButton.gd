extends TextureButton

class_name CircleButton


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func update_cost(new_cost):
	$Label.text = "$%s" % new_cost

func _set(property: String, value) -> bool:
	if property == "disabled":
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
#	if disabled:
#		$AnimationPlayer.play("disabled", 0, 4)
		
func _on_pressed_mid_point():
	if disabled:
		$AnimationPlayer.stop()
		var time = 0.25
		$Tween.interpolate_property(self, "modulate", modulate, Color("cc9c9c9c"), time)
		$Tween.interpolate_property(self, "self_modulate", self_modulate, Color.white, time)
		$Tween.interpolate_property(self, "rect_scale", rect_scale, Vector2(0.8, 0.8), time)
		
		$Tween.start()
#		self_modulate = Color.white
#		modulate = Color("cc9c9c9c")
	pass
