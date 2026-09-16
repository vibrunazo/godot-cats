extends Node2D

var selected: String = "Map01"
@onready var el_mainmenu: PauseMenu = $"%MainMenu"
@onready var el_lang: OptionButton = $"%LangOption"
enum State {START, LEVEL_SELECT}
var state: int = State.START

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimBG.play("start", 0, 0.2)
	Global.reset_volume()
#	el_mainmenu.set_focus()
	ini_lang_options()
	update_lang_from_locale()
	reset_focus()
	for b in get_tree().get_nodes_in_group("level"):
#		var button: ToolButton = b
#		print("found level button %s" % b.get_name())
		b.connect("pressed", Callable(self, "level_pressed").bind(b.get_name()))
		b.connect("button_down", Callable(self, "level_pressed").bind(b.get_name()))
		b.connect("focus_entered", Callable(self, "level_pressed").bind(b.get_name()))

func ini_lang_options() -> void:
	el_lang.clear()
	el_lang.add_item("en", 0)
	el_lang.set_item_icon(0, preload("res://assets/us.png"))
	el_lang.add_item("pt_BR", 1)
	el_lang.set_item_icon(1, preload("res://assets/brazil.png"))


func update_lang_from_locale() -> void:
	if el_lang.item_count < 2:
		return
	if !DisplayServer.has_feature(DisplayServer.FEATURE_TOUCHSCREEN):
		# no touch, I'm on PC
		el_lang.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	if TranslationServer.get_locale().begins_with("en"):
		el_lang.select(0)
	else:
		el_lang.select(1)
		
func play_selected_level() -> void:
	get_tree().change_scene_to_file("res://scenes/maps/%s.tscn" % selected)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and state == State.LEVEL_SELECT:
		var focus: Control = el_mainmenu.get_viewport().gui_get_focus_owner()
		if focus and focus.is_in_group('level'):
			play_selected_level()
	elif event.is_action_pressed("ui_accept") and !el_mainmenu.get_viewport().gui_get_focus_owner():
		el_mainmenu.set_focus()

func level_pressed(level_name: String) -> void:
	selected = level_name

func _on_ResumeButton_pressed() -> void:
	$Anim.play("out")
	state = State.LEVEL_SELECT
	$CanvasLayer/LevelSelectMenu/VBox/ScrollContainer/VBoxContainer/Map01.grab_focus()

func _on_PlayLevelButton_pressed() -> void:
	play_selected_level()

func _on_LevelBackButton_pressed() -> void:
	$Anim.play_backwards("out")
	state = State.START
	el_mainmenu.set_focus()

func reset_focus() -> void:
	await get_tree().create_timer(0.3).timeout
	state = State.START
	var focus: Control = el_mainmenu.get_viewport().gui_get_focus_owner()
	if focus == null:
		el_mainmenu.set_focus()
	else:
		print('focus is already on %s' % focus)
	focus = el_mainmenu.get_viewport().gui_get_focus_owner()

func _on_LangOption_item_selected(index: int) -> void:
	print('changed lang to %s' % index)
	if index == 0:
		TranslationServer.set_locale('en')
	else:
		TranslationServer.set_locale('pt_BR')
