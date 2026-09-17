extends SceneTree

## Temporary gameplay harness (not shipped): drives a real Map01 session
## through the public action flow, builds cats, fast-forwards combat,
## captures a mid-combat screenshot, and prints PLAYTEST verdicts.

var _failures: int = 0


func _init() -> void:
	_safety_timeout()
	call_deferred("_run")


func _safety_timeout() -> void:
	await create_timer(25.0, true, false, true).timeout
	print("PLAYTEST TIMEOUT: process exceeded safety limit")
	quit(1)


func _check(cond: bool, label: String) -> void:
	if cond:
		print("PLAYTEST ok: ", label)
	else:
		_failures += 1
		print("PLAYTEST FAIL: ", label)


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
	_check(is_instance_valid(map), "map instance valid")
	map.add_coins(500)
	# Build two cats next to the road through the real UI flow.
	await _build_cat_at(map, "Cat1", Vector2(320, 320))
	await _build_cat_at(map, "Cat2", Vector2(832, 320))
	for i: int in range(10):
		await process_frame
	_check(map.get_node("Actors").get_child_count() == 2, "two cats built")
	_check(map.coins == 530, "build costs deducted (55+500-10-15)")
	# Fast-forward combat.
	Engine.time_scale = 6.0
	for i: int in range(600):
		await process_frame
	Engine.time_scale = 1.0
	print("PLAYTEST info: spawn_count=", map.spawn_count, " kill_count=", map.kill_count,
		" stolen=", map.stolen_count, " coins=", map.coins, " life=", map.life)
	_check(map.spawn_count > 0, "mice spawned")
	_check(map.kill_count + map.stolen_count > 0, "mice resolved (killed or reached cheese)")
	_check(map.kill_count > 0, "cats killed at least one mouse")
	_check(map.coins > 530, "kill rewards paid")
	# Pause overlay on/off.
	map.toggle_pause()
	await process_frame
	await process_frame
	_check(paused, "pause engages tree pause")
	map.toggle_pause()
	await process_frame
	_check(!paused, "unpause releases tree pause")
	# Mid-combat screenshot for visual review (skipped in headless mode).
	var tex: ViewportTexture = root.get_texture()
	if tex != null:
		var img: Image = tex.get_image()
		if img != null:
			var err: Error = img.save_png("res://captures/new/combat.png")
			_check(err == OK, "combat screenshot saved")
		else:
			print("PLAYTEST info: viewport texture image is null (headless mode), skipping screenshot")
	else:
		print("PLAYTEST info: viewport texture is null (headless mode), skipping screenshot")
	if is_instance_valid(current_scene):
		current_scene.queue_free()
		current_scene = null
	await process_frame
	await process_frame
	if _failures > 0:
		print("PLAYTEST RESULT: FAIL (", _failures, ")")
		quit(1)
		return
	print("PLAYTEST RESULT: PASS")
	quit(0)


func _build_cat_at(map: Node, cat_name: String, pos: Vector2) -> void:
	map.action_pressed(cat_name, null)
	for i: int in range(2):
		await process_frame
	if map.cat_building == null:
		_failures += 1
		print("PLAYTEST FAIL: no cat_building for ", cat_name)
		return
	if !map.can_build(pos):
		_failures += 1
		print("PLAYTEST FAIL: cannot build ", cat_name, " at ", pos)
		map.cancel_build()
		return
	map.cat_building.global_position = pos
	map.action_released(cat_name, null)
