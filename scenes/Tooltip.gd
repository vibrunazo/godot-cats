extends PanelContainer

class_name Tooltip

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
#	var root = get_tree().current_scene
##	if root is Map:
##	root.on_tooltip_spawned(self)
	print('parent is %s' % get_parent())
#	get_parent().call_deferred("remove_tooltip", self)

func show():
	visible = true
	yield(get_tree().create_timer(5), "timeout")
	hide()

func hide():
	visible = false

func set_label(hint: String):
	$Label.text = hint
