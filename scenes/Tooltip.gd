extends PanelContainer

class_name Tooltip

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false

func show():
	visible = true
	yield(get_tree().create_timer(5), "timeout")
	hide()

func hide():
	visible = false

func set_label(hint: String):
	$Label.text = hint
