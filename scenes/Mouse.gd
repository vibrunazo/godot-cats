extends PathFollow2D

class_name Mouse, "res://assets/mouse01.png"
signal killed
signal cheese

var t = 0
export var speed := 50.0
export var max_health := 50.0
export var OFFSET_RANGE := 15
var health := 50.0
var alive := true
var worth := 1
enum State {READY, GRABBED, CHEESE, DEAD}
var state: int = State.READY
var tail_rot: Transform2D 
onready var el_tail_follow: PathFollow2D = $TailFollow

var rng: RandomNumberGenerator = Global.rng

func _ready():
	health = max_health
	start_walking()
	update_scale()
#	calculate_worth()
	ini_offsets()
	if Global.DEBUG_MOUSE:
		print("mouse ready with %s health and %s speed" % [health, speed])

func get_bullet_target():
	return $BulletTarget.global_position

func end():
	alive = false
	queue_free()
	el_tail_follow.queue_free()
	
func start_walking():
	$AnimationPlayer.play("walk", 0, 1.4) #1.4 speed
	
func ini_offsets():
#	h_offset = rng.randf_range(-OFFSET_RANGE, OFFSET_RANGE) * 2
	v_offset = rng.randf_range(-OFFSET_RANGE, OFFSET_RANGE)
	remove_child(el_tail_follow)
	get_parent().add_child(el_tail_follow)
	el_tail_follow.h_offset = h_offset
	el_tail_follow.v_offset = v_offset
	tail_rot = $Sprite/SpriteTail.global_transform
	
func update_worth(hp: float):
	worth = calculate_worth(hp)
	
static func calculate_worth(hp: float) -> int:
	# 40hp is 2 coins, 125hp is 3 coins, 245 is 4 coins
	var w = 1 + floor(pow(hp, 0.6) / 9)
	if hp <= 8:
		w = 0.2
	return w

func show_target_index(show: bool, index: String = ''):
#	if !Global.DEBUG: return
	$TargetIndexLabel.visible = show
	$TargetIndexLabel.text = index

func _physics_process(delta):
	if !is_ready():
		return
	# if I got to the end of the map
	if unit_offset >= 1.0:
		state = State.CHEESE
		emit_signal("cheese")
		end()
		return
	update_tail_rot(delta)
	update_offset(delta)

func update_offset(delta):
	if $AnimationPlayer.current_animation != "walk":
		return
# warning-ignore:unused_variable
	var final_speed := speed
	if $AnimationPlayer.current_animation_position < 0.125:
		final_speed = speed * 4
	else:
		final_speed = speed * 0.25
#	t += delta * final_speed
	t += delta * speed
	offset = t
	el_tail_follow.offset = offset - 50

func update_tail_rot(delta):
	if offset < 50:
		tail_rot = $Sprite/TailRot.global_transform
		return
#	var tail_rot = Vector2(500,300)
	var tail_loc = el_tail_follow.global_position
	$Sprite/TailRot.look_at(tail_loc)
	$Sprite/TailRot.rotation_degrees += 180
#	$Sprite/SpriteTail.look_at(tail_loc)
#	tail_rot = lerp(tail_rot, $Sprite/TailRot.global_rotation, delta * 10)
	tail_rot = $Sprite/SpriteTail.get_global_transform()
	tail_rot = tail_rot.interpolate_with($Sprite/TailRot.get_global_transform(), delta * 12)
#	tail_rot = $Sprite/TailRot.get_global_transform()
#	$Sprite/SpriteTail.rotation_degrees += 180
	$Sprite/SpriteTail.global_rotation = tail_rot.get_rotation()
#	$Turret.global_transform = $Turret.global_transform.interpolate_with(target_tran, turn_speed * get_physics_process_delta_time())
	
func update_scale():
	var size = 0.5 + pow(health, 0.75) * 0.02
	size = min(size, 1.7)
	scale = Vector2(size, size)

func is_ready() -> bool:
	return state == State.READY
	
func is_grabbed() -> bool:
	return state == State.GRABBED

func on_hit(bullet: Node2D):
	if !alive or !is_ready(): return
	health -= bullet.damage
#	$Audio.play()
	# if the hit killed me, die
	if health <= 0 and alive:
		health = 0
		alive = false
		state = State.DEAD
		emit_signal("killed")
		$AudioDie.play()
		$AnimationPlayer.play("dying")
		var vel: Vector2 = Vector2(1,0).rotated(bullet.rotation - rotation)
		vel = vel.normalized()
		vel *= rand_range(60, 140)
		$Tween.interpolate_property($Sprite, "rotation_degrees", $Sprite.rotation_degrees, $Sprite.rotation_degrees + rand_range(-190, 190), 0.6, Tween.TRANS_QUART, Tween.EASE_OUT)
		$Tween.interpolate_property($Sprite, "position", $Sprite.position, $Sprite.position + vel, 0.6, Tween.TRANS_QUART, Tween.EASE_OUT)
		$Tween.start()
		yield($AnimationPlayer,"animation_finished")
		end()
	# if hit didn't kill me, just play get hit anim
	else:
		update_scale()
		$AnimationPlayer.play("gethit")
		yield($AnimationPlayer, "animation_finished")
		start_walking()
		
func on_get_grabbed(_cat: Node2D):
#	print('%s grabbed by %s' % [name, cat.name])
	state = State.GRABBED
	$AnimationPlayer.play("grabbed")
	emit_signal("killed")

func on_finished_eaten():
	end()
