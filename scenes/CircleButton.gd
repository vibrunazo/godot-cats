extends TextureButton

class_name CircleButton, "res://assets/button_circle.png"

export var cost := 10

func _ready():
	pass # Replace with function body.
	
func update_cost(new_cost):
	cost = new_cost
	$Label.text = "$%s" % new_cost

#func _set(property: String, value) -> bool:
#	if property == "disabled":
#		set_disabled(value)
#		return true
#	return false

func set_disabled(value: bool):
	if disabled != value:
		print('updating disabled')
		disabled = value
		if disabled:
			$AnimationPlayer.play("disabled")
		else:
			$AnimationPlayer.play("enabled")

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
		
#		$Tween.start()
#		self_modulate = Color.white
#		modulate = Color("cc9c9c9c")

func set_state_from_coins(new_coins):
	if new_coins >= cost:
		set_disabled(false)
	else:
		set_disabled(true)
