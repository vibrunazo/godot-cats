extends "res://scenes/cats/Cat.gd"

class_name Cat2, "res://assets/cat02.png"


# Called when the node enters the scene tree for the first time.
func _ready():
	._ready()
	bullet_scene = preload("res://scenes/Bullet02.tscn")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
