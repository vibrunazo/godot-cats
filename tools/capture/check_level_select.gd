extends SceneTree
## Runtime theme regression check; pass -- capture=<absolute PNG path> for a screenshot.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	create_timer(15.0).timeout.connect(func() -> void: quit(1))
	TranslationServer.set_locale("en")
	var scene: Node = load("res://scenes/maps/MainScene.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.5).timeout
	scene.call("_on_ResumeButton_pressed")
	await create_timer(1.0).timeout
	var menu: Control = scene.get_node("CanvasLayer/LevelSelectMenu") as Control
	var button: Button = menu.get_node("VBox/ScrollContainer/VBoxContainer/Map01") as Button
	print("BUTTON flat=", button.flat, " outline=", button.get_theme_constant("outline_size"), " outline_color=", button.get_theme_color("font_outline_color"))
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style: StyleBox = button.get_theme_stylebox(state)
		print("STYLE ", state, " ", style.get_class(), " margins=", style.get_minimum_size())
	print("DISABLED COLOR ", button.get_theme_color("font_disabled_color"))
	var buttons: Array[Node] = menu.find_children("*", "Button", true, false)
	for node: Node in buttons:
		var item: Button = node as Button
		assert(item.flat, "%s lost its ToolButton flat styling" % item.name)
		assert(item.get_theme_constant("outline_size") > 0, "Missing text outline")
		assert(item.get_theme_color("font_outline_color") == Color.BLACK)
		assert(item.get_theme_color("font_disabled_color").a < item.get_theme_color("font_color").a)
		for state: String in ["disabled", "focus", "hover", "pressed", "hover_pressed"]:
			assert(item.get_theme_color("font_%s_color" % state) == menu.theme.get_color("font_%s_color" % state, "Button"))
	assert(button.has_focus(), "Initial level selection lost focus")
	var focus_style: StyleBoxFlat = button.get_theme_stylebox("focus") as StyleBoxFlat
	assert(focus_style != null and not focus_style.draw_center and focus_style.shadow_size > 0)
	var next_button: Button = button.get_parent().get_node("Map02") as Button
	next_button.grab_focus()
	assert(scene.get("selected") == next_button.name, "Focus no longer selects the level")
	button.grab_focus()
	print("PASS: ", buttons.size(), " flat outlined buttons, state colors, focus and selection")
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("capture="):
			await RenderingServer.frame_post_draw
			var image: Image = root.get_texture().get_image()
			if image == null or image.save_png(argument.trim_prefix("capture=")) != OK:
				quit(1)
				return
			print("CAPTURE saved")
	await process_frame
	scene.queue_free()
	current_scene = null
	await process_frame
	await process_frame
	print("CHECK completed")
	quit(0)
