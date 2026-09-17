extends PanelContainer

class_name Tooltip

@onready var el_label: Label = $"%Label"
@onready var el_desc: RichTextLabel = $"%DescriptionLabel"
var registered: bool = false
var labelled: bool = false
var _base_pos: Vector2 = Vector2.ZERO
var _has_base_pos: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false

# registers this tooltip on the map, so the map can place it in the appropriate layer
# called by the CircleButton, or the Cat
func register_tooltip() -> void:
	call_deferred("_register_with_map")


func _register_with_map() -> void:
	var root: Node = get_tree().current_scene
	if root == null:
		return
	if !root.has_method("register_new_tooltip"):
		return
	root.call_deferred("register_new_tooltip", self)

# adjust the position of the tooltip to fit inside the screen if it's being cut off
func adjust_position() -> void:
#	var tp = $"%Label".text.left(5)
#	print('tp: %s, gpos: %s, lpos: %s, size: %s, vp: %s' % [tp, get_global_transform().origin, rect_position, rect_size, get_viewport_rect().size])
	if !_has_base_pos:
		_base_pos = position
		_has_base_pos = true
	position = _base_pos
	var pos: Vector2 = get_global_transform().origin
	var tooltip_size: Vector2 = Vector2(
		max(size.x, get_combined_minimum_size().x),
		max(size.y, get_combined_minimum_size().y)
	)
	var vp: Vector2 = get_viewport_rect().size
	if vp.x <= 100.0 or vp.y <= 100.0:
		vp = Vector2(
			ProjectSettings.get_setting("display/window/size/viewport_width", 1664),
			ProjectSettings.get_setting("display/window/size/viewport_height", 768)
		)
	var left: float = pos.x
	var right: float = pos.x + tooltip_size.x
#	var top = pos.y
	var bot: float = pos.y + tooltip_size.y
#	if top < 0:
#		var delta = -top
#		rect_position.y += delta
	if left < 0.0:
		var delta_left: float = -left
		position.x += delta_left
	if right > vp.x:
		var delta_right: float = right - vp.x
		position.x -= delta_right
	if bot > vp.y:
		var delta_bot: float = bot - vp.y
		position.y -= delta_bot
#	print('tooltip moved to g: %s, l: %s' % [pos, rect_position])

## Shows the tooltip, optionally auto-hiding after `duration` seconds.
## Named show_tooltip/hide_tooltip: native CanvasItem.show/hide cannot be
## overridden (static calls bind to the native), so shadowing them crashes.
func show_tooltip(duration: float = -1.0) -> void:
	adjust_position()
	visible = true
	if duration != 0.0:
		$VisibilityTimer.start(duration)

func hide_tooltip() -> void:
	visible = false

## Shows and centers the panel within the current viewport rect.
func popup_centered() -> void:
	visible = true
	var vp_size: Vector2 = get_viewport_rect().size
	if vp_size.x <= 100.0 or vp_size.y <= 100.0:
		vp_size = Vector2(
			ProjectSettings.get_setting("display/window/size/viewport_width", 1664),
			ProjectSettings.get_setting("display/window/size/viewport_height", 768)
		)
	var self_size: Vector2 = get_combined_minimum_size()
	size = self_size
	position = (vp_size - self_size) / 2.0



func set_label(hint: String, desc: String = '') -> void:
	labelled = true
	el_label.text = hint
	el_desc.text = desc
	if desc.length() > 0:
		el_desc.fit_content = true
#		if desc.length() > 30:
#			el_desc.custom_minimum_size.x = 460
	else:
		el_desc.fit_content = false

func _on_VisibilityTimer_timeout() -> void:
	hide_tooltip()

func _on_Tooltip_resized() -> void:
	if !registered or !labelled: return
#	print('tooltip resized to %s' % rect_size)
	adjust_position()
