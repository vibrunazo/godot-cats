extends SceneTree
## Pause / cancel input test: asserts P toggles pause through the gear
## button's shortcut, gear clicks do the same, Escape exits the pause menu,
## Escape leaves the level select screen, and Escape is inert on the main menu.

func _init() -> void:
	call_deferred("_run")

func _key(code: Key) -> void:
	for down: bool in [true, false]:
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = down
		root.push_input(event)
		await process_frame

func _click(control: Control) -> void:
	var center: Vector2 = control.get_global_rect().get_center()
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = center
	root.push_input(motion)
	for down: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.position = center
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		event.pressed = down
		root.push_input(event)
		await process_frame

func _run() -> void:
	create_timer(20.0).timeout.connect(func() -> void:
		push_error("PAUSE TEST FAILED: timed out")
		quit(1))
	var pause_events: Array[InputEvent] = InputMap.action_get_events("pause")
	assert(pause_events.size() == 1, "pause action should have exactly one binding")
	var pause_key: InputEventKey = pause_events[0] as InputEventKey
	assert(pause_key != null and pause_key.physical_keycode == KEY_P, "pause must be bound to the P key")
	assert(InputMap.action_get_events("ui_cancel").size() >= 1, "ui_cancel has no bindings")
	print("PASS: pause=P and ui_cancel bindings present")
	# The headless dummy viewport is 64x64, which pushes the HUD off-screen;
	# match the project window so synthetic clicks land on real controls.
	root.size = Vector2i(1664, 768)
	await process_frame
	await process_frame

	# --- gameplay: P toggles pause through the gear button; gear clicks too
	var map: Node = load("res://scenes/maps/Map01.tscn").instantiate()
	root.add_child(map)
	current_scene = map
	await create_timer(0.7).timeout
	var gear: Button = map.get_node("%SettingsButton") as Button
	var pause_menu: Control = map.get_node("%PauseMenu") as Control
	assert(gear != null and pause_menu != null, "Map is missing the gear button or pause menu")
	var gear_pressed: Array[int] = [0]
	gear.pressed.connect(func() -> void: gear_pressed[0] += 1)
	await _key(KEY_P)
	assert(paused and gear_pressed[0] == 1, "P did not pause via the gear shortcut")
	await create_timer(0.6).timeout
	assert(pause_menu.visible, "Pause menu did not become visible after pausing")
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("capture="):
			await RenderingServer.frame_post_draw
			var image: Image = root.get_texture().get_image()
			if image == null or image.save_png(argument.trim_prefix("capture=")) != OK:
				push_error("PAUSE TEST FAILED: capture could not be saved")
				quit(1)
				return
			print("CAPTURE saved")
	await _key(KEY_P)
	assert(not paused and gear_pressed[0] == 2, "P did not resume via the gear shortcut")
	await create_timer(0.7).timeout
	assert(not pause_menu.visible, "Pause menu stayed visible after resuming")
	await _click(gear)
	assert(paused and gear_pressed[0] == 3, "Gear click did not pause")
	await _click(gear)
	assert(not paused and gear_pressed[0] == 4, "Gear click did not resume")
	await _key(KEY_P)
	assert(paused and gear_pressed[0] == 5, "P paused again but did not fire the gear shortcut")
	await _key(KEY_ESCAPE)
	await create_timer(0.7).timeout
	assert(not paused and gear_pressed[0] == 5 and not pause_menu.visible, "Escape did not exit the pause menu")
	print("PASS: P and gear toggle pause; Escape exits the pause menu")
	map.queue_free()
	current_scene = null
	await process_frame
	await process_frame

	# --- menus: Escape leaves level select and is inert on the main menu
	var main: Node = load("res://scenes/maps/MainScene.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await create_timer(0.7).timeout
	var menu: Control = main.get_node("CanvasLayer/LevelSelectMenu") as Control
	var back: Button = menu.get_node("Margin/BackButton") as Button
	var back_pressed: Array[int] = [0]
	back.pressed.connect(func() -> void: back_pressed[0] += 1)
	await _key(KEY_ESCAPE)
	await create_timer(0.3).timeout
	assert(main.get("state") == 0 and back_pressed[0] == 0, "Escape on the main menu leaked into the hidden back button")
	await _key(KEY_ENTER)
	await create_timer(0.7).timeout
	assert(main.get("state") == 1, "Enter did not open level select")
	await _key(KEY_ESCAPE)
	await create_timer(0.3).timeout
	assert(main.get("state") == 0, "Escape did not leave level select")
	assert(back_pressed[0] == 1, "Escape did not trigger the back button exactly once")
	print("PASS: Escape leaves level select and is inert on the main menu")
	main.queue_free()
	current_scene = null
	await process_frame
	await process_frame
	print("PAUSE TEST completed")
	quit(0)
