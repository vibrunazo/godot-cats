extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	await process_frame
	var packed: PackedScene = load("res://scenes/maps/Map01.tscn") as PackedScene
	var map: Node2D = packed.instantiate() as Node2D
	root.add_child(map)
	current_scene = map
	for i: int in range(20):
		await process_frame
	var lab: Label = map.get_node("UI/HUD/ActionBar/M1/Cat1/Label") as Label
	var f: Font = lab.get_theme_font("font", "Label")
	print("DIAG price font=", f.resource_path if (f as Resource).resource_path != "" else "(builtin " + f.get_class() + ")")
	var mpacked: PackedScene = load("res://scenes/maps/MainScene.tscn") as PackedScene
	var menu: Node = mpacked.instantiate()
	root.add_child(menu)
	for i: int in range(20):
		await process_frame
	var title: Label = menu.get_node("CanvasLayer/MainMenu/HBoxContainer/MainMenu") as Label
	var tf: Font = title.get_theme_font("font", "Label")
	print("DIAG title font=", tf.resource_path if (tf as Resource).resource_path != "" else "(builtin " + tf.get_class() + ")")
	print("DIAG title size=", title.get_theme_font_size("font_size", "Label"), " outline=", title.get_theme_constant("outline_size", "Label"))
	quit(0)
