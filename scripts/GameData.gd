extends Node

var cat_data = {
	"Cat1": {
		'id': 0,
		'cost': 10
	},
	"Cat2": {
		'id': 1,
		'cost': 15
	}
}
var cat_scenes = [
	preload("res://scenes/Cat.tscn"),
	preload("res://scenes/Cat02.tscn")
	]


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	print('gamedata ready')
	pass # Replace with function body.
	
func get_cat_data(name: String):
	return cat_data[name]

func get_cat_scene(name: String):
	return cat_scenes[cat_data[name]['id']]
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
