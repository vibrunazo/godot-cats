extends PanelContainer

class_name Tooltip

onready var el_label: Label = $"%Label"
onready var el_desc: RichTextLabel = $"%DescriptionLabel"
var registered := false
var labelled := false

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false

# registers this tooltip on the map, so the map can place it in the appropriate layer
# called by the CircleButton, or the Cat
func register_tooltip():
	var root = get_tree().current_scene
	root.call_deferred("register_new_tooltip", self)

# adjust the position of the tooltip to fit inside the screen if it's being cut off
func adjust_position():
#	var tp = $"%Label".text.left(5)
#	print('tp: %s, gpos: %s, lpos: %s, size: %s, vp: %s' % [tp, get_global_transform().origin, rect_position, rect_size, get_viewport_rect().size])
	var pos := get_global_transform().origin
	var size := rect_size
	var vp := get_viewport_rect().size
	var left = pos.x 
	var right = pos.x + size.x 
#	var top = pos.y
	var bot = pos.y + size.y
#	if top < 0:
#		var delta = -top
#		rect_position.y += delta
	if left < 0:
		var delta = -left
		rect_position.x += delta
	if right > vp.x:
		var delta = right - vp.x
		rect_position.x -= delta
	if bot > vp.y:
		var delta = bot - vp.y
		rect_position.y -= delta
#	print('tooltip moved to g: %s, l: %s' % [pos, rect_position])

func show(duration: float = -1):
#	adjust_position()
	visible = true
	if duration != 0:
		$VisibilityTimer.start(duration)

func hide():
	visible = false

func set_label(hint: String, desc: String = ''):
	labelled = true
	el_label.text = hint
	el_desc.bbcode_text = desc
	if desc.length() > 0:
		el_desc.fit_content_height = true
#		if desc.length() > 30:
#			el_desc.rect_min_size.x = 460
	else:
		el_desc.fit_content_height = false

func _on_VisibilityTimer_timeout():
	hide()

func _on_Tooltip_resized():
	if !registered or !labelled: return
#	print('tooltip resized to %s' % rect_size)
	adjust_position()
