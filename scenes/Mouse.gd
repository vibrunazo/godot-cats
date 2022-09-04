extends PathFollow2D

class_name Mouse, "res://assets/mouse01.png"
signal killed
signal cheese

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var t = 0
export var speed := 50.0
export var max_health := 50.0
export var OFFSET_RANGE := 15
var health := 50.0
var alive := true

var rng: RandomNumberGenerator = Global.rng


# Called when the node enters the scene tree for the first time.
func _ready():
	health = max_health
	start_walking()
	update_scale()
	h_offset = rng.randf_range(-OFFSET_RANGE, OFFSET_RANGE) * 2
	v_offset = rng.randf_range(-OFFSET_RANGE, OFFSET_RANGE)
	if Global.DEBUG_MOUSE:
		print("mouse ready with %s health and %s speed" % [health, speed])
#	$Sprite.offset = Vector2(rng.randf_range(-OFFSET_RANGE, OFFSET_RANGE) * 2, rng.randf_range(-OFFSET_RANGE, OFFSET_RANGE))

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func get_bullet_target():
	return $BulletTarget.global_position

func end():
	alive = false
	queue_free()
	
func start_walking():
	$AnimationPlayer.play("walk", 0, 1.4)

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
	var size = 0.6 + pow(health, 0.75) * 0.02
	size = min(size, 1.6)
	scale = Vector2(size, size)

func on_hit(bullet: Node2D):
	if !alive: return
	health -= bullet.damage
#	$Audio.play()
	if health <= 0 and alive:
		health = 0
		alive = false
		emit_signal("killed")
		$AnimationPlayer.play("dying")
		$Tween.interpolate_property(self, "rotation_degrees", rotation_degrees, rotation_degrees + rand_range(-190, 190), 0.6, Tween.TRANS_QUART, Tween.EASE_OUT)
		$Tween.interpolate_property(self, "position", position, position + Vector2(rand_range(-50, 50), rand_range(-50, 50)), 0.6, Tween.TRANS_QUART, Tween.EASE_OUT)
		
		$Tween.start()
		yield($AnimationPlayer,"animation_finished")
		end()
	else:
		update_scale()
		$AnimationPlayer.play("gethit")
		yield($AnimationPlayer, "animation_finished")
		start_walking()
