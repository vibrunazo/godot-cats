extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var DEBUG = false
var DEBUG_MAP_TIMER = false
var DEBUG_MOUSE = false
var DEBUG_WIN = false
var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	print('global script is ready, DEBUG is %s' % DEBUG)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
