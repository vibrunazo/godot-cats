extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var DEBUG = false


# Called when the node enters the scene tree for the first time.
func _ready():
	print('global script is ready, DEBUG is %s' % DEBUG)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
