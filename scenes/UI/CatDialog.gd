extends ConfirmationDialog

class_name CatDialog

func reset_margin():
	$PanelHighlight.margin_bottom = 0
	$PanelHighlight.margin_left = 0
	$PanelHighlight.margin_right = 0
	$PanelHighlight.margin_top = 0
	
func set_title(new_title: String):
	$"%Title".text = new_title
	
func set_text(new_text):
	$"%Text".bbcode_text = new_text

func set_icon(new_icon: Texture):
	$"%Icon".texture = new_icon

func _on_CatDialog_item_rect_changed():
	reset_margin()
