extends Node2D

class_name Bullet, "res://assets/ball.png"

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var speed = 400
export var damage = 10
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
	if is_instance_valid(target):
		look_at(target.global_position)
		position += Vector2(speed * delta, 0).rotated(rotation)
	else:
		queue_free()


func _on_Area2D_area_entered(area: Node2D):
	if (area.get_parent() == target):
		var mouse: Mouse = area.get_parent()
		mouse.on_hit(self)
		queue_free()
