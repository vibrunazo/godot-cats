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
	map.action_pressed("Cat1", null)
	for i: int in range(2):
		await process_frame
	map.cat_building.global_position = Vector2(832, 320)
	map.action_released("Cat1", null)
	for i: int in range(10):
		await process_frame
	var cat: Node2D = map.get_cat_at(Vector2(832, 320))
	map.select_cat(cat)
	for i: int in range(60):
		await process_frame
	var img: Image = root.get_texture().get_image()
	print("SELIMG saved=", img.save_png("res://captures/new/selected.png") == OK)
	quit(0)
