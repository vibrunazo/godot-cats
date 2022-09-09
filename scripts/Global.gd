extends Node


var DEBUG = false
var DEBUG_MAP_TIMER = false
var DEBUG_MOUSE = false
var DEBUG_WIN = false
var rng = RandomNumberGenerator.new()
var master_volume = -10
var game_volume = 0

func _ready():
	rng.randomize()
	print('global script is ready, DEBUG is %s' % DEBUG)
	set_volume(master_volume)

func set_volume(volume: float):
	set_bus_volume(volume)
	
func reset_volume():
	set_volume(master_volume)

func set_bus_volume(volume: float, bus: String = "Master"):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), volume)

func set_game_volume(volume: float):
#	print('fading game volume to %s' % volume)
	set_bus_volume(volume, "game")

func fade_out_game_volume():
#	print('fading out')
	var tween: SceneTreeTween = get_tree().create_tween()
	tween.set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_method(self, "set_game_volume", game_volume, -80, 0.8)

func fade_in_game_volume():
#	print('fading in')
	var tween: SceneTreeTween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_method(self, "set_game_volume", -80, game_volume, 0.8)
