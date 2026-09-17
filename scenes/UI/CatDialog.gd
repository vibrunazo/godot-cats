extends Tooltip

class_name CatDialog

## Confirmation dialog for cat upgrades and deletions.
## Inherits from Tooltip to share the game's panel theme, rounded corners,
## drop shadow, and highlight border box.

signal confirmed
signal canceled

@onready var el_icon: TextureRect = $"%Icon"
@onready var el_cancel_btn: Button = $"%CancelButton"
@onready var el_ok_btn: Button = $"%OkButton"
@onready var el_close_btn: TextureButton = $"%CloseButton"


func _ready() -> void:
	super._ready()
	if has_node("VisibilityTimer"):
		$VisibilityTimer.stop()
	mouse_filter = Control.MOUSE_FILTER_STOP
	if el_ok_btn != null and !el_ok_btn.pressed.is_connected(_on_ok_pressed):
		el_ok_btn.pressed.connect(_on_ok_pressed)
	if el_cancel_btn != null and !el_cancel_btn.pressed.is_connected(_on_cancel_pressed):
		el_cancel_btn.pressed.connect(_on_cancel_pressed)
	if el_close_btn != null and !el_close_btn.pressed.is_connected(_on_close_pressed):
		el_close_btn.pressed.connect(_on_close_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()
		get_viewport().set_input_as_handled()


## Shows and centers the dialog in the viewport.
func popup_centered() -> void:
	super.popup_centered()



## Sets the dialog title label.
func set_popup_title(new_title: String) -> void:
	if el_label != null:
		el_label.text = new_title


## Sets the dialog body text.
func set_popup_text(new_text: String) -> void:
	if el_desc != null:
		el_desc.text = new_text
		el_desc.fit_content = true


## Sets the dialog icon texture.
func set_popup_icon(new_icon: Texture2D) -> void:
	if el_icon != null:
		el_icon.texture = new_icon
		el_icon.visible = (new_icon != null)


## Returns the OK button instance.
func get_ok_button() -> Button:
	return el_ok_btn


## Returns the Cancel button instance.
func get_cancel_button() -> Button:
	return el_cancel_btn


## Resets the highlight panel margins (kept for backwards compatibility).
func reset_margin() -> void:
	pass


func _on_ok_pressed() -> void:
	emit_signal("confirmed")
	visible = false


func _on_cancel_pressed() -> void:
	emit_signal("canceled")
	visible = false


func _on_close_pressed() -> void:
	emit_signal("canceled")
	visible = false
