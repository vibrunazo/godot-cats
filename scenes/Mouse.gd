extends PathFollow2D

class_name Mouse, "res://assets/mouse01.png"

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var t = 0
export var speed := 100


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _physics_process(delta):
	t += delta * speed
	offset = t
#	print("I'm a mouse at %s" % position)

