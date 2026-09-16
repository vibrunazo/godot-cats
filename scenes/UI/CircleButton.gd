@icon("res://assets/button_circle.png")
extends TextureButton

class_name CircleButton

@export var cost: int = 10
@export var confirm: bool = true
@onready var el_tooltip: Tooltip = $'%Tooltip'
@onready var el_label: Label = $"%Label"
var action: Action = null

func _ready() -> void:
	update_cost(cost)
	call_deferred("_register_with_map")


func _register_with_map() -> void:
	var root: Node = get_tree().current_scene
	if root == null:
		return
	if !root.has_method("register_new_button"):
		return
#	print("root %s is class %s" % [root, root.get_class()])
	root.call_deferred("register_new_button", self)

# register tooltip with the map, so the map can place the tooltip in the correct layer
# called by the cat when the button is in a cat
# called by the map when it's an action button
func register_tooltip() -> void:
	el_tooltip.register_tooltip()

func show_tooltip(duration: float = -1.0) -> void:
	el_tooltip.show_tooltip(duration)

func hide_tooltip() -> void:
	el_tooltip.hide_tooltip()

func update_cost(new_cost: int) -> void:
	cost = new_cost
	if cost > 0:
		el_label.text = "$%s" % new_cost
	else:
		el_label.text = "+$%s" % abs(new_cost)
	
func update_icon(new_icon: Texture2D, icon_size: Vector2 = Vector2(64, 64), color: Color = Color.WHITE) -> void:
	$CenterContainer/TextureRect.texture = new_icon
	$CenterContainer/TextureRect.custom_minimum_size = icon_size
	$CenterContainer/TextureRect.modulate = color

## Applies the disabled look/state. Named set_button_disabled: native
## BaseButton.set_disabled cannot be overridden (static calls bind native).
func set_button_disabled(value: bool) -> void:
	if disabled != value:
		disabled = value
		if disabled:
			$AnimationPlayer.play("disabled", -1, 1 / Engine.time_scale)
		else:
			$AnimationPlayer.play("enabled", -1, 1 / Engine.time_scale)

func _on_CircleButton_pressed() -> void:
	$AnimationPlayer.play("pressed", -1, 1.0 / Engine.time_scale)

func _on_pressed_mid_point() -> void:
	if disabled:
		$AnimationPlayer.stop()
		var time: float = 0.25
		var press_tween: Tween = create_tween().set_parallel(true)
		press_tween.tween_property(self, "modulate", Color("#9c9c9ccc"), time)
		press_tween.tween_property(self, "self_modulate", self_modulate, time)
		press_tween.tween_property(self, "scale", Vector2(0.8, 0.8), time)
#		self_modulate = Color.white
#		modulate = Color("cc9c9c9c")

func set_state_from_coins(new_coins: float) -> void:
	if new_coins >= cost:
		set_button_disabled(false)
	else:
		set_button_disabled(true)
