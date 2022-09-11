extends Node2D

var selected = "Map01"
onready var el_mainmenu: PauseMenu = $"%MainMenu"
enum State {START, LEVEL_SELECT}
var state: int = State.START

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimBG.play("start", 0, 0.2)
	Global.reset_volume()
#	el_mainmenu.set_focus()
	reset_focus()
	for b in get_tree().get_nodes_in_group("level"):
#		var button: ToolButton = b
#		print("found level button %s" % b.get_name())
		b.connect("pressed", self, "level_pressed", [b.get_name()])
		b.connect("button_down", self, "level_pressed", [b.get_name()])
		b.connect("focus_entered", self, "level_pressed", [b.get_name()])
		
func play_selected_level():
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://scenes/maps/%s.tscn" % selected)

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept") and state == State.LEVEL_SELECT:
		var focus := el_mainmenu.get_focus_owner()
		if focus.is_in_group('level'):
			play_selected_level()
	elif event.is_action_pressed("ui_accept") and !el_mainmenu.get_focus_owner():
		el_mainmenu.set_focus()

func level_pressed(name: String):
	selected = name

func _on_ResumeButton_pressed():
	$Anim.play("out")
	state = State.LEVEL_SELECT
	$CanvasLayer/LevelSelectMenu/VBox/ScrollContainer/VBoxContainer/Map01.grab_focus()

func _on_PlayLevelButton_pressed():
# warning-ignore:return_value_discarded
	play_selected_level()


func _on_LevelBackButton_pressed():
	$Anim.play_backwards("out")
	state = State.START
	el_mainmenu.set_focus()


func reset_focus():
	yield(get_tree().create_timer(0.3), "timeout")
	state = State.START
	var focus = el_mainmenu.get_focus_owner()
	if focus == null:
		el_mainmenu.set_focus()
	else:
		print('focus is already on %s' % focus)
	focus = el_mainmenu.get_focus_owner()
