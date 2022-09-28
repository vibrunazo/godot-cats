extends PanelContainer

class_name Tooltip

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false

# registers this tooltip on the map, so the map can place it in the appropriate layer
# called by the CircleButton 
func register_tooltip():
	var root = get_tree().current_scene
	root.call_deferred("register_new_tooltip", self)

func show():
	visible = true
	$VisibilityTimer.start()

func hide():
	visible = false

func set_label(hint: String):
	$Label.text = hint


func _on_VisibilityTimer_timeout():
	hide()
