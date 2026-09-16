extends SceneTree

## Standalone capture helper, run with: godot --path . -s <this> -- scene=<tscn> output=<png> wait_frames=<n>
## Inherits SceneTree and quits explicitly so the main loop shuts down cleanly.

var _scene: String = "res://scenes/maps/MainScene.tscn"
var _output: String = "captures/new/capture.png"
var _wait_frames: int = 120
var _pause_after_frames: int = -1
var _tooltip_button_index: int = -1


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("scene="):
			_scene = arg.trim_prefix("scene=")
		elif arg.begins_with("output="):
			_output = arg.trim_prefix("output=")
		elif arg.begins_with("wait_frames="):
			_wait_frames = int(arg.trim_prefix("wait_frames="))
		elif arg.begins_with("pause_after_frames="):
			_pause_after_frames = int(arg.trim_prefix("pause_after_frames="))
		elif arg.begins_with("tooltip_button_index="):
			_tooltip_button_index = int(arg.trim_prefix("tooltip_button_index="))
	call_deferred("_run")


func _run() -> void:
	# Project translations (internationalization/locale/translations in
	# project.godot) are loaded automatically by the engine in every mode,
	# including -s scripts — nothing to set up here. NOTE: a Godot 3-style
	# [locale]/translations= entry is silently ignored by Godot 4 and the
	# game will show raw translation keys; convert it if you see that.
	var packed: PackedScene = load(_scene) as PackedScene
	if packed == null:
		push_error("capture helper: cannot load scene %s" % _scene)
		quit(1)
		return
	var inst: Node = packed.instantiate()
	root.add_child(inst)
	current_scene = inst

	if _pause_after_frames >= 0:
		for i: int in range(_pause_after_frames):
			await process_frame
		if inst.has_method("toggle_pause"):
			inst.toggle_pause()
		elif inst.has_node("%PauseMenu"):
			var pm: Node = inst.get_node("%PauseMenu")
			if pm.has_method("pause"):
				pm.pause(true)
		for i: int in range(_wait_frames):
			await process_frame
	else:
		for i: int in range(_wait_frames):
			await process_frame

	if _tooltip_button_index >= 0:
		var action_buttons: Variant = inst.get("action_buttons")
		if action_buttons != null and _tooltip_button_index < action_buttons.size():
			inst.call("show_tooltip_on", action_buttons[_tooltip_button_index])
			for i: int in range(10):
				await process_frame
	# Two extra frames so the viewport texture is fully rendered.
	await process_frame
	await process_frame
	var img: Image = root.get_texture().get_image()
	var err: Error = img.save_png(_output)
	if err != OK:
		push_error("capture helper: save_png failed (%s) for %s" % [err, _output])
		quit(1)
		return
	print("capture helper: saved %s (%dx%d)" % [_output, img.get_width(), img.get_height()])
	# Clean shutdown so exit is leak-free: free the scene (stops music/timers)
	# before quitting the main loop.
	if is_instance_valid(current_scene):
		current_scene.queue_free()
		current_scene = null
	await process_frame
	await process_frame
	quit(0)
