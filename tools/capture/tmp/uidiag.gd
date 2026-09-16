extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for tr_path: String in ProjectSettings.get_setting("locale/translations", []):
		var tr_res: Translation = load(tr_path) as Translation
		if tr_res != null:
			TranslationServer.add_translation(tr_res)
	var packed: PackedScene = load("res://scenes/maps/Map01.tscn") as PackedScene
	var map: Node2D = packed.instantiate() as Node2D
	root.add_child(map)
	current_scene = map
	for i: int in range(30):
		await process_frame
	var cheese: TextureRect = map.get_node("UI/HUD/TopBar/CheeseIcon") as TextureRect
	if cheese == null:
		print("DIAG topbar children:")
		for c: Node in map.get_node("UI/HUD/TopBar").get_children():
			print("DIAG  - ", c.name, " type=", c.get_class())
	else:
		print("DIAG cheese rect=", cheese.get_rect(), " tex=", (cheese.texture as Texture2D).get_size() if cheese.texture else Vector2.ZERO, " expand=", cheese.expand_mode, " stretch=", cheese.stretch_mode)
	var btn: Node = map.get_node("UI/HUD/ActionBar/M1/Cat1")
	print("DIAG btn size=", (btn as Control).size, " min=", (btn as Control).custom_minimum_size)
	var cc: Node = btn.get_node("CenterContainer")
	print("DIAG cc class=", cc.get_class(), " rect=", (cc as Control).get_rect())
	var trr: TextureRect = cc.get_child(0) as TextureRect
	print("DIAG icon rect=", trr.get_rect(), " min=", trr.custom_minimum_size, " tex=", (trr.texture as Texture2D).get_size() if trr.texture else Vector2.ZERO, " expand=", trr.expand_mode, " stretch=", trr.stretch_mode)
	var lab: Label = btn.get_node("Label") as Label
	print("DIAG label font=", (lab.get_theme_font("font", "Label") as Font).get_class() if lab.has_theme_font("font", "Label") else lab.get_theme_default_font().resource_name, " size=", lab.get_theme_font_size("font_size", "Label"), " outline=", lab.get_theme_constant("outline_size", "Label"), " theme=", (lab.theme as Resource).resource_path if lab.theme else "inherited")
	quit(0)
