extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var speed = 400
var target: Node2D = null setget set_target


# Called when the node enters the scene tree for the first time.
#func _ready():
#	look_at(Vector2(400, 200))
#	rotation_degrees = 60

func set_target(new_target: Node2D):
	target = new_target
	look_at(target.position)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _physics_process(delta):
	position += Vector2(speed * delta, 0).rotated(rotation)
