extends ConfirmationDialog

class_name CatDialog

func reset_margin():
	$PanelHighlight.margin_bottom = 0
	$PanelHighlight.margin_left = 0
	$PanelHighlight.margin_right = 0
	$PanelHighlight.margin_top = 0
	
func set_text(new_text):
	$"%Text".bbcode_text = new_text

func _on_CatDialog_item_rect_changed():
	reset_margin()
