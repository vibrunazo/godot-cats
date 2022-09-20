extends Area2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
#func _unhandled_input(event):
#	print('unhandled input')
	
func _input_event(_viewport, event: InputEvent, _shape_idx):
	if event is InputEventMouseButton and !event.is_pressed():
		if !get_parent().is_building():
			get_parent().emit_signal("clicked")
