extends ConfirmationDialog

class_name CatDialog


func _ready() -> void:
	transparent = true
	transparent_bg = true
	var cancel_btn: Button = get_cancel_button()
	var ok_btn: Button = get_ok_button()
	if cancel_btn != null and ok_btn != null:
		var empty_sb: StyleBoxEmpty = StyleBoxEmpty.new()
		cancel_btn.add_theme_stylebox_override("focus", empty_sb)
		ok_btn.add_theme_stylebox_override("focus", empty_sb)
		var hbox: Node = cancel_btn.get_parent()
		if hbox != null and hbox.get_child_count() >= 4:
			hbox.move_child(cancel_btn, 1)
			hbox.move_child(ok_btn, 3)


## Resets the highlight panel margins (called when the dialog resizes).
func reset_margin() -> void:
	$PanelHighlight.offset_bottom = -80.0
	$PanelHighlight.offset_left = 6.0
	$PanelHighlight.offset_right = -6.0
	$PanelHighlight.offset_top = 6.0




## Sets the dialog title label.
## Named set_popup_* to avoid clashing with native Window/AcceptDialog setters.
func set_popup_title(new_title: String) -> void:
	$"%Title".text = new_title


## Sets the dialog body text.
func set_popup_text(new_text: String) -> void:
	$"%Text".text = new_text


## Sets the dialog icon texture.
func set_popup_icon(new_icon: Texture2D) -> void:
	$"%Icon".texture = new_icon


func _on_CatDialog_item_rect_changed() -> void:
	reset_margin()
