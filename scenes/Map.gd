extends Node2D


var el_path: Path2D
var mouse_scene = preload("res://scenes/Mouse.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	el_path = $Path2D


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func spawn_new_mouse():
	var mouse = mouse_scene.instance()
	mouse.position = Vector2(0, 0)
	el_path.add_child(mouse)

func _on_SpawnTimer_timeout():
	spawn_new_mouse()
	

