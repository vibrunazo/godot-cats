extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var DEBUG = false
var DEBUG_MAP_TIMER = false
var DEBUG_MOUSE = false
var DEBUG_WIN = false
var rng = RandomNumberGenerator.new()
var master_volume = -10

func _ready():
	rng.randomize()
	print('global script is ready, DEBUG is %s' % DEBUG)
	set_volume(master_volume)

func set_volume(volume):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume)
	
func reset_volume():
	set_volume(master_volume)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
