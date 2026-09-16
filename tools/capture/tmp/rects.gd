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
	var btn: Control = map.get_node("UI/HUD/ActionBar/M1/Cat1") as Control
	var icon: Control = btn.get_node("CenterContainer/TextureRect") as Control
	print("DIAG btn global=", btn.get_global_rect(), " icon global=", icon.get_global_rect())
	var li: Control = map.get_node("UI/HUD/TopBar/LifeIconRoot/LifeIcon") as Control
	print("DIAG cheese global=", li.get_global_rect(), " min=", li.custom_minimum_size)
	quit(0)
