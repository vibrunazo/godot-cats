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

var rng: RandomNumberGenerator = Global.rng

func _ready():
	health = max_health
	start_walking()
	update_scale()
#	calculate_worth()
	h_offset = rng.randf_range(-OFFSET_RANGE, OFFSET_RANGE) * 2
	v_offset = rng.randf_range(-OFFSET_RANGE, OFFSET_RANGE)
	if Global.DEBUG_MOUSE:
		print("mouse ready with %s health and %s speed" % [health, speed])

func get_bullet_target():
	return $BulletTarget.global_position

func end():
	alive = false
	queue_free()
	
func start_walking():
	$AnimationPlayer.play("walk", 0, 1.4)
	
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
	# if I got to the end of the map
	if unit_offset >= 1.0:
		emit_signal("cheese")
		end()
		return
	if $AnimationPlayer.current_animation != "walk":
		return
	var final_speed := speed
	if $AnimationPlayer.current_animation_position < 0.125:
		final_speed = speed * 4
	else:
		final_speed = speed * 0.25
	t += delta * final_speed
	offset = t

func update_scale():
	var size = 0.5 + pow(health, 0.75) * 0.02
	size = min(size, 1.7)
	scale = Vector2(size, size)

func on_hit(bullet: Node2D):
	if !alive: return
	health -= bullet.damage
#	$Audio.play()
	if health <= 0 and alive:
		health = 0
		alive = false
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
	else:
		update_scale()
		$AnimationPlayer.play("gethit")
		yield($AnimationPlayer, "animation_finished")
		start_walking()
