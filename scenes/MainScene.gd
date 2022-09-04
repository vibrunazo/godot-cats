extends Node2D

var selected = "Map01"

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimBG.play("start", 0, 0.2)
	
	for b in get_tree().get_nodes_in_group("level"):
		var button: ToolButton = b
		print("found level button %s" % b.get_name())
		b.connect("pressed", self, "level_pressed", [b.get_name()])
		b.connect("button_down", self, "level_down", [b.get_name()])


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func level_pressed(name: String):
	print('pressed: %s' % name)
	selected = name
	
func level_down(name: String):
	print('down: %s' % name)
	selected = name

func _on_ResumeButton_pressed():
	$Anim.play("out")

func _on_PlayLevelButton_pressed():
	var focused = $CanvasLayer/LevelSelectMenu.get_focus_owner()
	print(focused)
	get_tree().change_scene("res://scenes/maps/%s.tscn" % selected)


func _on_LevelBackButton_pressed():
	$Anim.play_backwards("out")
