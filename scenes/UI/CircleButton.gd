extends TextureButton

class_name CircleButton, "res://assets/button_circle.png"

export var cost: int = 10
export var confirm: bool = true
onready var el_tooltip: Tooltip = $'%Tooltip'
onready var el_label: Label = $"%Label"
var action = null

func _ready():
	update_cost(cost)
	var root = get_tree().current_scene
#	print("root %s is class %s" % [root, root.get_class()])
	root.call_deferred("register_new_button", self)

# register tooltip with the map, so the map can place the tooltip in the correct layer
# called by the cat when the button is in a cat
# called by the map when it's an action button
func register_tooltip():
	el_tooltip.register_tooltip()

func show_tooltip(duration = -1):
	el_tooltip.show(duration)

func hide_tooltip():
	el_tooltip.hide()

func update_cost(new_cost: int):
	cost = new_cost
	if cost > 0:
		el_label.text = "$%s" % new_cost
	else:
		el_label.text = "+$%s" % abs(new_cost)
	
func update_icon(new_icon: Texture, size: Vector2 = Vector2(64, 64), color: Color = Color.white):
	$CenterContainer/TextureRect.texture = new_icon
	$CenterContainer/TextureRect.rect_min_size = size
	$CenterContainer/TextureRect.modulate = color

func set_disabled(value: bool):
	if disabled != value:
		disabled = value
		if disabled:
			$AnimationPlayer.play("disabled", -1, 1 / Engine.time_scale)
		else:
			$AnimationPlayer.play("enabled", -1, 1 / Engine.time_scale)

func _on_CircleButton_pressed():
	$AnimationPlayer.play("pressed", -1, 1 / Engine.time_scale)

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
