extends SceneTree

## UI Dump Helper: loads a scene and prints Control hierarchy, layout modes, anchors, and rects.
## Run with: godot --path . -s res://tools/capture/ui_dump_helper.gd -- scene=<tscn> [node=<path>] [frames=<n>]

var _scene: String = ""
var _target_node: String = ""
var _wait_frames: int = 10


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("scene="):
			_scene = arg.trim_prefix("scene=")
		elif arg.begins_with("node="):
			_target_node = arg.trim_prefix("node=")
		elif arg.begins_with("frames="):
			_wait_frames = int(arg.trim_prefix("frames="))
	call_deferred("_run")


func _run() -> void:
	var tr_paths: Array = ProjectSettings.get_setting("internationalization/locale/translations", [])
	if tr_paths.is_empty():
		tr_paths = ProjectSettings.get_setting("locale/translations", [])
	for tr_path: String in tr_paths:
		var tr_res: Translation = load(tr_path) as Translation
		if tr_res != null:
			TranslationServer.add_translation(tr_res)

	if _scene.is_empty():
		push_error("ui_dump_helper: scene parameter required (e.g. scene=res://scenes/maps/Map01.tscn)")
		quit(1)
		return

	var packed: PackedScene = load(_scene) as PackedScene
	if packed == null:
		push_error("ui_dump_helper: cannot load scene %s" % _scene)
		quit(1)
		return

	var inst: Node = packed.instantiate()
	root.add_child(inst)
	current_scene = inst

	for i: int in range(_wait_frames):
		await process_frame

	var target: Node = inst
	if not _target_node.is_empty():
		target = inst.get_node_or_null(_target_node)
		if target == null:
			push_error("ui_dump_helper: node %s not found in %s" % [_target_node, _scene])
			quit(1)
			return

	print("\n--- UI Layout Dump: %s (target: %s) ---" % [_scene, target.name])
	_dump_control_tree(target, 0)
	print("--- End UI Layout Dump ---\n")

	if is_instance_valid(current_scene):
		current_scene.queue_free()
		current_scene = null
	await process_frame
	quit(0)


func _layout_mode_name(mode: int) -> String:
	match mode:
		0: return "POSITIONED(0)"
		1: return "ANCHORED(1)"
		2: return "CONTAINER(2)"
		3: return "UNCONFIGURED(3)"
		_: return "UNKNOWN(%d)" % mode


func _dump_control_tree(node: Node, depth: int) -> void:
	var indent: String = "  ".repeat(depth)
	if node is Control:
		var c: Control = node as Control
		var g_rect: Rect2 = c.get_global_rect()
		var center: Vector2 = g_rect.position + g_rect.size / 2.0
		var extra: String = ""
		if c is TextureButton:
			var tb: TextureButton = c as TextureButton
			extra += " [TB: ignore_tex_size=%s, stretch_mode=%d]" % [tb.ignore_texture_size, tb.stretch_mode]
		elif c is TextureRect:
			var tr: TextureRect = c as TextureRect
			extra += " [TR: expand_mode=%d, stretch_mode=%d]" % [tr.expand_mode, tr.stretch_mode]
		elif c is MarginContainer:
			extra += " [MC: margins=(L:%d,T:%d,R:%d,B:%d)]" % [
				c.get_theme_constant("margin_left"),
				c.get_theme_constant("margin_top"),
				c.get_theme_constant("margin_right"),
				c.get_theme_constant("margin_bottom")
			]

		print("%s* %s (%s)%s" % [indent, c.name, c.get_class(), extra])
		print("%s  pos=%s size=%s min_size=%s center=%s" % [indent, c.position, c.size, c.custom_minimum_size, center])
		print("%s  layout_mode=%s anchors=(L:%.2f, T:%.2f, R:%.2f, B:%.2f) offsets=(L:%.1f, T:%.1f, R:%.1f, B:%.1f)" % [
			indent, _layout_mode_name(c.layout_mode),
			c.anchor_left, c.anchor_top, c.anchor_right, c.anchor_bottom,
			c.offset_left, c.offset_top, c.offset_right, c.offset_bottom
		])
	else:
		print("%s* %s (%s)" % [indent, node.name, node.get_class()])

	for child: Node in node.get_children():
		_dump_control_tree(child, depth + 1)
