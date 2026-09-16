extends SceneTree

## Standalone capture helper, run with: godot --path . -s <this> -- scene=<tscn> output=<png> wait_frames=<n>
## Inherits SceneTree and quits explicitly so the main loop shuts down cleanly.

var _scene: String = "res://scenes/maps/MainScene.tscn"
var _output: String = "captures/new/capture.png"
var _wait_frames: int = 120


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("scene="):
			_scene = arg.trim_prefix("scene=")
		elif arg.begins_with("output="):
			_output = arg.trim_prefix("output=")
		elif arg.begins_with("wait_frames="):
			_wait_frames = int(arg.trim_prefix("wait_frames="))
	call_deferred("_run")


func _run() -> void:
	# NOTE: -s scripts bypass automatic project translation loading,
	# so load them explicitly to match normal game startup.
	# Godot 4 lists them under "internationalization/locale/translations";
	# fall back to the Godot 3 path for unconverted projects.
	var tr_paths: Array = ProjectSettings.get_setting("internationalization/locale/translations", [])
	if tr_paths.is_empty():
		tr_paths = ProjectSettings.get_setting("locale/translations", [])
	for tr_path: String in tr_paths:
		var tr_res: Translation = load(tr_path) as Translation
		if tr_res != null:
			TranslationServer.add_translation(tr_res)
	var packed: PackedScene = load(_scene) as PackedScene
	if packed == null:
		push_error("capture helper: cannot load scene %s" % _scene)
		quit(1)
		return
	var inst: Node = packed.instantiate()
	root.add_child(inst)
	current_scene = inst
	for i: int in range(_wait_frames):
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
