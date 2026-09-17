extends SceneTree
## End-to-end menu input test: drives real viewport input and asserts that
## Enter opens level select, clicking keeps the focus highlight owner, and
## Enter plays the focused level. Pass capture=<absolute PNG path> to also
## save a screenshot right after the mouse click.

func _init() -> void:
	call_deferred("_run")

func _key(code: Key) -> void:
	for down: bool in [true, false]:
		var event: InputEventKey = InputEventKey.new()
		event.keycode = code
		event.pressed = down
		root.push_input(event)
		await process_frame

func _click(position: Vector2) -> void:
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = position
	root.push_input(motion)
	for down: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.position = position
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		event.pressed = down
		root.push_input(event)
		await process_frame

func _fail(message: String) -> void:
	push_error("MENU TEST FAILED: " + message)
	quit(1)

func _run() -> void:
	create_timer(20.0).timeout.connect(func() -> void: quit(1))
	var actions: Array[InputEvent] = InputMap.action_get_events("ui_accept")
	assert(actions.size() >= 3, "ui_accept lost its default bindings")
	var has_enter: bool = false
	for action: InputEvent in actions:
		var key: InputEventKey = action as InputEventKey
		if key and key.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			has_enter = true
	assert(has_enter, "ui_accept has no keyboard binding")
	var scene: Node = load("res://scenes/maps/MainScene.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.7).timeout
	var resume: Button = scene.get_node("CanvasLayer/MainMenu/HBoxContainer/ResumeButton") as Button
	assert(root.gui_get_focus_owner() == resume, "Main menu did not focus its play button")
	await _key(KEY_ENTER)
	await create_timer(0.7).timeout
	assert(scene.get("state") == 1, "Enter on the play button did not open level select")
	print("PASS: Enter opens level select")
	var menu: Control = scene.get_node("CanvasLayer/LevelSelectMenu") as Control
	var button: Button = menu.get_node("VBox/ScrollContainer/VBoxContainer/Map02") as Button
	await _click(button.get_global_rect().get_center())
	assert(root.gui_get_focus_owner() == button, "Clicking a level did not focus it")
	assert(button.has_focus() and scene.get("selected") == "Map02")
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("capture="):
			await RenderingServer.frame_post_draw
			var image: Image = root.get_texture().get_image()
			if image == null or image.save_png(argument.trim_prefix("capture=")) != OK:
				push_error("MENU TEST FAILED: capture could not be saved")
				quit(1)
				return
			print("CAPTURE saved")
	await _key(KEY_DOWN)
	var moved: Button = menu.get_node("VBox/ScrollContainer/VBoxContainer/Map03") as Button
	assert(root.gui_get_focus_owner() == moved, "Arrow keys did not move focus after a click")
	await _key(KEY_ENTER)
	await create_timer(0.5).timeout
	if current_scene == null or current_scene.scene_file_path != "res://scenes/maps/Map03.tscn":
		push_error("MENU TEST FAILED: Enter did not play the focused level")
		quit(1)
		return
	print("PASS: Enter plays the focused level")
	current_scene.queue_free()
	current_scene = null
	await process_frame
	await process_frame
	print("MENU TEST completed")
	quit(0)
