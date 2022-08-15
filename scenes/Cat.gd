extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var aggro_list = []
var target: Mouse


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_AggroRange_area_entered(area: Node):
	if !area.get_parent().is_in_group("mice"):
		return
	print('entered range %s' % area.get_parent().is_in_group("mice"))
	target = area.get_parent()


func _on_AggroRange_area_exited(area):
	if !area.get_parent().is_in_group("mice"):
		return
	print('exited range')
