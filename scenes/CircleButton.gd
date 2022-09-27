extends TextureButton

class_name CircleButton, "res://assets/button_circle.png"

export var cost := 10
onready var el_tooltip: Tooltip = $'%Tooltip'

func _ready():
	update_cost(cost)
	el_tooltip.set_label(hint_tooltip)

func show_tooltip() -> Tooltip:
	el_tooltip.show()
	return el_tooltip

func hide_tooltip():
	el_tooltip.hide()
	
func update_cost(new_cost):
	cost = new_cost
	$Label.text = "$%s" % new_cost

func set_disabled(value: bool):
	if disabled != value:
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

func set_state_from_coins(new_coins):
	if new_coins >= cost:
		set_disabled(false)
	else:
		set_disabled(true)
