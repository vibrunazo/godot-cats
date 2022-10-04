extends Node

onready var cat_data = {
	"Cat1": {
		'id': 0,
		'full_name': tr('cat1'),
		'description': tr('cat1_description'),
		'cost': 10
	},
	"Cat2": {
		'id': 1,
		'full_name': tr('cat2'),
		'description': tr('cat2_description'),
		'cost': 15
	},
	"Cat3": {
		'id': 2,
		'full_name': tr('cat3'),
		'description': tr('cat3_description'),
		'cost': 20
	}
}
var cat_scenes = [
	preload("res://scenes/cats/Cat01.tscn"),
	preload("res://scenes/cats/Cat02.tscn"),
	preload("res://scenes/cats/Cat03.tscn")
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
