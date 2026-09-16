extends Node

## Global autoload for shared debug flags, RNG, and audio bus volume helpers.
## Preserved from the original Godot 3 project; migrated to Godot 4 Tween API.

var DEBUG: bool = false
var DEBUG_MAP_TIMER: bool = false
var DEBUG_MOUSE: bool = false
var DEBUG_WIN: bool = false
var DEBUG_WAVES: bool = false
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var master_volume: float = -10.0
var game_volume: float = 0.0


func _ready() -> void:
	rng.randomize()
	print('global script is ready, DEBUG is %s' % DEBUG)
	set_volume(master_volume)
#	TranslationServer.set_locale('en')


func set_volume(volume: float) -> void:
	set_bus_volume(volume)


func reset_volume() -> void:
	set_volume(master_volume)


func set_bus_volume(volume: float, bus: String = "Master") -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), volume)


func set_game_volume(volume: float) -> void:
#	print('fading game volume to %s' % volume)
	set_bus_volume(volume, "game")


func fade_out_game_volume() -> void:
#	print('fading out')
	var tween: Tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_method(Callable(self, "set_game_volume"), game_volume, -80.0, 0.8)


func fade_in_game_volume() -> void:
#	print('fading in')
	var tween: Tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_method(Callable(self, "set_game_volume"), -80.0, game_volume, 0.8)
