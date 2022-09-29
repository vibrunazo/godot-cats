extends PanelContainer

class_name Tooltip

onready var el_label: Label = $"%Label"

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false

# registers this tooltip on the map, so the map can place it in the appropriate layer
# called by the CircleButton 
func register_tooltip():
	var root = get_tree().current_scene
	root.call_deferred("register_new_tooltip", self)

# adjust the position of the tooltip to fit inside the screen if it's being cut off
func adjust_position():
	print('window real size: %s, window size: %s, pos: %s, size: %s, vp: %s' % [OS.get_real_window_size(), OS.window_size, get_global_transform().origin, rect_size, get_viewport_rect().size])
	var pos := get_global_transform().origin
	var size := rect_size
	var vp := get_viewport_rect().size
	var right = pos.x + size.x
	var bot = pos.y + size.y
	if bot > vp.y:
		var delta = bot - vp.y
		rect_position.y -= delta

func show():
	adjust_position()
	visible = true
	$VisibilityTimer.start()

func hide():
	visible = false

func set_label(hint: String):
	el_label.text = hint


func _on_VisibilityTimer_timeout():
	hide()
