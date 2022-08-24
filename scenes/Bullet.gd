extends Node2D

class_name Bullet, "res://assets/ball.png"

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var speed = 400
export var damage = 10
var target: Mouse = null setget set_target
var target_offset: Vector2 = Vector2(0, 0)


# Called when the node enters the scene tree for the first time.
func _ready():
	target_offset = Vector2(rand_range(-20, 20), rand_range(-20, 20))
#	look_at(Vector2(400, 200))
#	rotation_degrees = 60

func set_target(new_target: Mouse):
	target = new_target
	var target_pos = target.get_bullet_target() + target_offset
	look_at(target_pos)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _physics_process(delta):
	if is_instance_valid(target):
		var target_pos = target.get_bullet_target() + target_offset
		look_at(target_pos)
		position += Vector2(speed * delta, 0).rotated(rotation)
	else:
		queue_free()


func _on_Area2D_area_entered(area: Node2D):
	if (area.get_parent() == target):
		var mouse: Mouse = area.get_parent()
		mouse.on_hit(self)
		queue_free()
