extends SceneTree

## Gameplay harness (not shipped): builds a Cat1 next to the road in a real Map01,
## gives it the teacup upgrade and lets it fight at normal speed. Checks that the
## teacup attack plays its own animation and still releases one bullet per attack.
## Pair with --write-movie to record the knock-over for a visual check:
##   godot --path . --write-movie captures/new/teacup.avi --fixed-fps 30 -s res://tools/capture/playtest_teacup.gd

var _failures: int = 0
var _shots: int = 0
var _attacks: int = 0


func _init() -> void:
	_safety_timeout()
	call_deferred("_run")


func _safety_timeout() -> void:
	await create_timer(40.0, true, false, true).timeout
	print("PLAYTEST TIMEOUT: process exceeded safety limit")
	quit(1)


func _check(cond: bool, label: String) -> void:
	if cond:
		print("PLAYTEST ok: ", label)
	else:
		_failures += 1
		print("PLAYTEST FAIL: ", label)


func _run() -> void:
	var map: Node2D = (load("res://scenes/maps/Map01.tscn") as PackedScene).instantiate() as Node2D
	root.add_child(map)
	current_scene = map
	for i: int in range(30):
		await process_frame
	map.add_coins(500)
	map.action_pressed("Cat1", null)
	for i: int in range(2):
		await process_frame
	var cat: Node2D = map.cat_building
	map.cat_building.global_position = Vector2(320, 320)
	map.action_released("Cat1", null)
	for i: int in range(10):
		await process_frame
	_check(is_instance_valid(cat), "teacup cat built")
	cat.call("up_teacup")
	var player: AnimationPlayer = cat.get_node("AnimationPlayer") as AnimationPlayer
	player.animation_started.connect(func(anim: StringName) -> void:
		if anim == StringName(cat.get("attack_anim")):
			_attacks += 1)
	cat.connect("shot", func(_bullet: Node) -> void: _shots += 1)
	var t0: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 12000 and _shots < 4:
		await process_frame
	# let the last attack animation finish before counting
	for i: int in range(60):
		await process_frame
	print("PLAYTEST info: attacks=", _attacks, " shots=", _shots, " anim=", cat.get("attack_anim"))
	_check(String(cat.get("attack_anim")) != "attack", "teacup uses its own attack animation")
	_check(_shots > 0, "teacup cat released bullets")
	_check(_shots <= _attacks and _shots >= _attacks - 1, "one bullet per attack animation")
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
