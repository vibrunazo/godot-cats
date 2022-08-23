extends PathFollow2D

class_name Mouse, "res://assets/mouse01.png"
signal killed

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var t = 0
export var speed := 50
export var max_health := 100
export var OFFSET_RANGE := 15
var health := 100
var alive := true

var rng: RandomNumberGenerator = Global.rng


# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationPlayer.play("walk")
	h_offset = rng.randf_range(-OFFSET_RANGE, OFFSET_RANGE) * 2
	v_offset = rng.randf_range(-OFFSET_RANGE, OFFSET_RANGE)
#	$Sprite.offset = Vector2(rng.randf_range(-OFFSET_RANGE, OFFSET_RANGE) * 2, rng.randf_range(-OFFSET_RANGE, OFFSET_RANGE))

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func end():
	alive = false
	queue_free()

func show_target_index(show: bool, index: String = ''):
#	if !Global.DEBUG: return
	$TargetIndexLabel.visible = show
	$TargetIndexLabel.text = index

func _physics_process(delta):
#	print("I'm a mouse at %s" % unit_offset)
	if unit_offset >= 1.0:
		end()
		return
	t += delta * speed
	offset = t

func on_hit(bullet: Node2D):
	health -= bullet.damage
	if health <= 0 and alive:
		health = 0
		alive = false
		emit_signal("killed")
		end()
