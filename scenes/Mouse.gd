@icon("res://assets/mouse01.png")
extends PathFollow2D

class_name Mouse
signal killed
signal cheese

var t: float = 0.0
@export var speed := 50.0
@export var max_health := 50.0
@export var OFFSET_RANGE := 15
var health := 50.0
var alive := true
var worth: float = 1.0
enum State {READY, GRABBED, CHEESE, DEAD}
var state: int = State.READY
var tail_rot: Transform2D = Transform2D.IDENTITY
@onready var el_tail_follow: PathFollow2D = $TailFollow

var rng: RandomNumberGenerator = Global.rng

func _ready() -> void:
	health = max_health
	start_walking()
	update_scale()
#	calculate_worth()
	ini_offsets()
	if Global.DEBUG_MOUSE:
		print("mouse ready with %s health and %s speed" % [health, speed])

func get_bullet_target() -> Vector2:
	return $BulletTarget.global_position

func end() -> void:
	alive = false
	queue_free()
	el_tail_follow.queue_free()

func start_walking() -> void:
	$AnimationPlayer.play("walk", 0, 1.4) #1.4 speed

func ini_offsets() -> void:
#	h_offset = rng.randf_range(-OFFSET_RANGE, OFFSET_RANGE) * 2
	v_offset = rng.randf_range(-OFFSET_RANGE, OFFSET_RANGE)
	remove_child(el_tail_follow)
	get_parent().add_child(el_tail_follow)
	el_tail_follow.h_offset = h_offset
	el_tail_follow.v_offset = v_offset
	tail_rot = $Sprite2D/SpriteTail.global_transform

func update_worth(hp: float) -> void:
	worth = calculate_worth(hp)

static func calculate_worth(hp: float) -> float:
	# 40hp is 2 coins, 125hp is 3 coins, 245 is 4 coins
	var w: float = 1.0 + floor(pow(hp, 0.6) / 9.0)
	if hp <= 8.0:
		w = 0.2
	return w

func show_target_index(should_show: bool, index: String = '') -> void:
#	if !Global.DEBUG: return
	$TargetIndexLabel.visible = should_show
	$TargetIndexLabel.text = index

func _physics_process(delta: float) -> void:
	if !is_ready():
		return
	# if I got to the end of the map
	if progress_ratio >= 1.0:
		state = State.CHEESE
		emit_signal("cheese")
		end()
		return
	update_tail_rot(delta)
	update_offset(delta)

func update_offset(delta: float) -> void:
	if $AnimationPlayer.current_animation != "walk":
		return
	@warning_ignore("unused_variable")
	var final_speed: float = speed
	if $AnimationPlayer.current_animation_position < 0.125:
		final_speed = speed * 4.0
	else:
		final_speed = speed * 0.25
#	t += delta * final_speed
	t += delta * speed
	progress = t
	el_tail_follow.progress = progress - 50.0

func update_tail_rot(delta: float) -> void:
	if progress < 50.0:
		tail_rot = $Sprite2D/TailRot.global_transform
		return
#	var tail_rot = Vector2(500,300)
	var tail_loc: Vector2 = el_tail_follow.global_position
	$Sprite2D/TailRot.look_at(tail_loc)
	$Sprite2D/TailRot.rotation_degrees += 180
#	$Sprite/SpriteTail.look_at(tail_loc)
#	tail_rot = lerp(tail_rot, $Sprite/TailRot.global_rotation, delta * 10)
	tail_rot = $Sprite2D/SpriteTail.get_global_transform()
	tail_rot = tail_rot.interpolate_with($Sprite2D/TailRot.get_global_transform(), delta * 12)
#	tail_rot = $Sprite/TailRot.get_global_transform()
#	$Sprite/SpriteTail.rotation_degrees += 180
	$Sprite2D/SpriteTail.global_rotation = tail_rot.get_rotation()
#	$Turret.global_transform = $Turret.global_transform.interpolate_with(target_tran, turn_speed * get_physics_process_delta_time())

func update_scale() -> void:
	var size: float = 0.5 + pow(health, 0.75) * 0.02
	size = min(size, 1.7)
	scale = Vector2(size, size)

func is_ready() -> bool:
	return state == State.READY

func is_grabbed() -> bool:
	return state == State.GRABBED

## Takes a hit from a Bullet or a Cat slap; both expose a `damage` value.
func on_hit(bullet: Node2D) -> void:
	if !alive or !is_ready(): return
	health -= float(bullet.get("damage"))
#	$Audio.play()
	# if the hit killed me, die
	if health <= 0 and alive:
		health = 0
		alive = false
		state = State.DEAD
		emit_signal("killed")
		$AudioDie.play()
		$AnimationPlayer.play("dying")
		var vel: Vector2 = Vector2(1, 0).rotated(bullet.rotation - rotation)
		vel = vel.normalized()
		vel *= randf_range(60.0, 140.0)
		var death_tween: Tween = create_tween().set_parallel(true)
		death_tween.tween_property($Sprite2D, "rotation_degrees", $Sprite2D.rotation_degrees + randf_range(-190.0, 190.0), 0.6).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		death_tween.tween_property($Sprite2D, "position", $Sprite2D.position + vel, 0.6).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		await $AnimationPlayer.animation_finished
		end()
	# if hit didn't kill me, just play get hit anim
	else:
		update_scale()
		$AnimationPlayer.play("gethit")
		await $AnimationPlayer.animation_finished
		start_walking()

func on_get_grabbed(_cat: Node2D) -> void:
#	print('%s grabbed by %s' % [name, cat.name])
	state = State.GRABBED
	$AnimationPlayer.play("grabbed")
	emit_signal("killed")

func on_finished_eaten() -> void:
	end()
