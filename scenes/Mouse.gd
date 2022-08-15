extends PathFollow2D

class_name Mouse, "res://assets/mouse01.png"

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var t = 0
export var speed := 30


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func end():
	print('daed mouse')
	queue_free()

func _physics_process(delta):
#	print("I'm a mouse at %s" % unit_offset)
	if unit_offset >= 1.0:
		end()
		return
	t += delta * speed
	offset = t

