extends ConfirmationDialog

class_name CatDialog

# Called when the node enters the scene tree for the first time.
func _ready():
	print("I'm a cat dialog")
	

func reset_margin():
	$PanelHighlight.margin_bottom = 0
	$PanelHighlight.margin_left = 0
	$PanelHighlight.margin_right = 0
	$PanelHighlight.margin_top = 0
	print('reset margin')
	
func set_text(new_text):
	$MarginContainer/RichTextLabel.bbcode_text = new_text

func _on_CatDialog_item_rect_changed():
	reset_margin()
