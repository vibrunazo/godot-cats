extends SceneTree

## Temporary harness part 2 (not shipped): cat upgrades (direct + popup),
## delete/refund, and game-over flow on Map01.

var _failures: int = 0


func _init() -> void:
	call_deferred("_run")


func _check(cond: bool, label: String) -> void:
	if cond:
		print("PLAYTEST2 ok: ", label)
	else:
		_failures += 1
		print("PLAYTEST2 FAIL: ", label)


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
	map.add_coins(500)
	var ConfigNode: Node = root.get_node("Config")
	# Hovering a shop button must show its tooltip (regression: Tooltip.show
	# shadowed the native PanelContainer.show and crashed with 1 arg).
	var shop_button: CircleButton = map.get_node("UI/HUD/ActionBar/M1/Cat1") as CircleButton
	map.button_entered(shop_button)
	for i: int in range(3):
		await process_frame
	_check(shop_button.el_tooltip.visible, "shop tooltip visible on hover")
	map.button_exited(shop_button)
	await _build_cat_at(map, "Cat1", Vector2(320, 320))
	await process_frame
	var cat = map.get_cat_at(Vector2(320, 320))
	_check(cat != null, "built cat found by position")
	# Hovering the built cat must show its tooltip without errors.
	map.show_tooltip_on(cat, 0.5)
	for i: int in range(3):
		await process_frame
	_check(cat.el_cat_tooltip.visible, "cat tooltip visible on hover")
	map.hide_tooltip_on(cat)
	var coins_after_build: int = map.coins
	# Direct upgrade path (no confirm dialog).
	ConfigNode.confirm = false
	var range_before: float = cat.aggro_range
	cat.action_pressed(cat.el_up1_button)
	_check(cat.aggro_range > range_before, "direct upgrade raised range (up_house)")
	_check(map.coins < coins_after_build, "direct upgrade cost coins")
	# Popup confirm path.
	ConfigNode.confirm = true
	var dmg_before: int = cat.damage
	cat.action_pressed(cat.el_up2_button)
	for i: int in range(5):
		await process_frame
	var popup: Node = null
	for child: Node in map.get_node("UI/Tooltips").get_children():
		if child is CatDialog:
			popup = child
	_check(popup != null, "confirm popup opened")
	popup.emit_signal("confirmed")
	for i: int in range(5):
		await process_frame
	_check(cat.damage > dmg_before, "popup confirm raised damage (up_yarn)")
	# Delete flow with refund.
	var worth_before: int = map.coins
	var refund: int = cat.get_delete_coins()
	var n_before: int = map.get_node("Actors").get_child_count()
	cat.on_delete_confirm()
	for i: int in range(5):
		await process_frame
	_check(map.get_node("Actors").get_child_count() == n_before - 1, "deleted cat removed")
	_check(map.coins == worth_before + refund, "delete refunded coins")
	_check(map.get_cat_at(Vector2(320, 320)) == null, "cell freed after delete")
	# Game over flow.
	map.add_life(-9999)
	for i: int in range(10):
		await process_frame
	_check(map.state == 1, "game over state reached")
	if is_instance_valid(current_scene):
		paused = false
		current_scene.queue_free()
		current_scene = null
	await process_frame
	await process_frame
	if _failures > 0:
		print("PLAYTEST2 RESULT: FAIL (", _failures, ")")
		quit(1)
		return
	print("PLAYTEST2 RESULT: PASS")
	quit(0)


func _build_cat_at(map: Node, cat_name: String, pos: Vector2) -> void:
	map.action_pressed(cat_name, null)
	for i: int in range(2):
		await process_frame
	if map.cat_building == null:
		_failures += 1
		print("PLAYTEST2 FAIL: no cat_building for ", cat_name)
		return
	map.cat_building.global_position = pos
	map.action_released(cat_name, null)
