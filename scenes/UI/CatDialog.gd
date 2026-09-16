extends ConfirmationDialog

class_name CatDialog


## Resets the highlight panel margins (called when the dialog resizes).
func reset_margin() -> void:
	$PanelHighlight.offset_bottom = 0
	$PanelHighlight.offset_left = 0
	$PanelHighlight.offset_right = 0
	$PanelHighlight.offset_top = 0


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
