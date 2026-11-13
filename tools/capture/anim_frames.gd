extends SceneTree

## Renders a contact sheet of one cat animation at fixed times, for checking poses
## without playing a level. Run with a display (not --headless):
##   godot --path . -s res://tools/capture/anim_frames.gd -- scene=res://scenes/cats/Cat01.tscn
##       anim=attack call=up_teacup times=0,0.1,0.2 output=captures/new/anim.png
## `call` is an optional method run on the cat before posing (e.g. an upgrade).
## Method tracks (like `shoot`) are disabled so no bullets need a real map.

var _scene: String = "res://scenes/cats/Cat01.tscn"
var _anim: String = "attack"
var _call: String = ""
var _times: PackedFloat32Array = PackedFloat32Array([0.0, 0.2, 0.4, 0.6])
var _output: String = "captures/new/anim.png"
var _cell: int = 220
var _zoom: float = 2.0
var _columns: int = 6


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("scene="):
			_scene = arg.trim_prefix("scene=")
		elif arg.begins_with("anim="):
			_anim = arg.trim_prefix("anim=")
		elif arg.begins_with("call="):
			_call = arg.trim_prefix("call=")
		elif arg.begins_with("times="):
			_times = PackedFloat32Array()
			for t: String in arg.trim_prefix("times=").split(","):
				_times.append(float(t))
		elif arg.begins_with("output="):
			_output = arg.trim_prefix("output=")
		elif arg.begins_with("cell="):
			_cell = int(arg.trim_prefix("cell="))
		elif arg.begins_with("zoom="):
			_zoom = float(arg.trim_prefix("zoom="))
		elif arg.begins_with("columns="):
			_columns = int(arg.trim_prefix("columns="))
	create_timer(30.0, true, false, true).timeout.connect(func() -> void: quit(1))
	call_deferred("_run")


func _run() -> void:
	RenderingServer.set_default_clear_color(Color(0.55, 0.7, 0.45))
	# Cats read their cost from the map in _ready; an off-tree Map is enough for that.
	# Map/Cat are loaded at runtime (not as class names) because -s scripts compile
	# before autoloads like Global exist.
	var map: Node = (load("res://scenes/maps/Map.gd") as GDScript).new() as Node
	var cat: Node2D = (load(_scene) as PackedScene).instantiate() as Node2D
	cat.call("init", map)
	cat.set("state", 1) # Cat.State.READY
	root.add_child(cat)
	var view: Vector2 = Vector2(root.size)
	cat.position = view / 2.0
	var cam: Camera2D = Camera2D.new()
	cam.position = cat.position
	cam.zoom = Vector2(_zoom, _zoom)
	root.add_child(cam)
	cam.make_current()
	cat.get_node("UIroot").visible = false
	cat.get_node("SelectRoot").visible = false
	if _call != "":
		cat.call(_call)

	var player: AnimationPlayer = cat.get_node("AnimationPlayer") as AnimationPlayer
	var anim: Animation = player.get_animation(_anim)
	if anim == null:
		push_error("anim_frames: no animation %s" % _anim)
		quit(1)
		return
	for i: int in anim.get_track_count():
		if anim.track_get_type(i) == Animation.TYPE_METHOD:
			anim.track_set_enabled(i, false)
	player.play(_anim)
	player.pause()

	var rows: int = ceili(float(_times.size()) / _columns)
	var cols: int = mini(_columns, _times.size())
	var sheet: Image = Image.create(cols * _cell, rows * _cell, false, Image.FORMAT_RGBA8)
	for i: int in _times.size():
		player.seek(_times[i], true)
		await process_frame
		await process_frame
		var img: Image = root.get_texture().get_image()
		if img == null:
			push_error("anim_frames: no viewport image (headless?)")
			quit(1)
			return
		img.convert(Image.FORMAT_RGBA8)
		var src: Rect2i = Rect2i(Vector2i(view / 2.0) - Vector2i(_cell, _cell) / 2, Vector2i(_cell, _cell))
		sheet.blit_rect(img, src, Vector2i((i % _columns) * _cell, (i / _columns) * _cell))
	var err: Error = sheet.save_png(_output)
	print("anim_frames: saved %s (%s)" % [_output, error_string(err)])
	cat.queue_free()
	map.free()
	await process_frame
	quit(0 if err == OK else 1)
