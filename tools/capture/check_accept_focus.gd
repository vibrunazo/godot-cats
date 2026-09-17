extends SceneTree
## Minimal reproduction: does _unhandled_input see ui_accept while a Button
## holds keyboard focus? Logs which input phases receive it. Read-only with
## respect to game code.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	create_timer(15.0).timeout.connect(func() -> void: quit(1))
	var listener_script: GDScript = GDScript.new()
	listener_script.source_code = "extends Node\nvar got_input: bool = false\nvar got_unhandled: bool = false\nfunc _input(event: InputEvent) -> void:\n\tif event.is_action_pressed(\"ui_accept\"):\n\t\tgot_input = true\nfunc _unhandled_input(event: InputEvent) -> void:\n\tif event.is_action_pressed(\"ui_accept\"):\n\t\tgot_unhandled = true\n"
	assert(listener_script.reload() == OK)
	var listener: Node = Node.new()
	listener.set_script(listener_script)
	root.add_child(listener)
	var button: Button = Button.new()
	button.text = "Level 01"
	root.add_child(button)
	button.grab_focus()
	var pressed: Array[bool] = [false]
	button.pressed.connect(func() -> void: pressed[0] = true)
	for down: bool in [true, false]:
		var event: InputEventKey = InputEventKey.new()
		event.keycode = KEY_ENTER
		event.pressed = down
		root.push_input(event)
		await process_frame
	print("REPRO focus=", root.gui_get_focus_owner())
	print("REPRO pressed=", pressed[0], " _input saw ui_accept=", listener.get("got_input"), " _unhandled_input saw ui_accept=", listener.get("got_unhandled"))
	quit(0)
