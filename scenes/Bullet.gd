extends Node2D

class_name Bullet, "res://assets/ball.png"

signal hit

export var speed = 400
export var damage = 10
export var aoe = false
export var turn_rate_min: float = 0
export var turn_rate_max: float = 0
export(Array, AudioStream) var sounds: Array
export(PackedScene) var blast_scene: PackedScene
var target: Mouse = null setget set_target
var target_offset: Vector2 = Vector2(0, 0)
var target_pos: Vector2 = Vector2(0, 0)
var ready = true
#var blast_scene = preload(blast)
#var blast_scene: PackedScene = preload("res://scenes/Blast.tscn")
var hit_pitch: float = 1
var velocity: Vector2
var turn_rate: float = 0


func _ready():
	target_offset = Vector2(rand_range(-12, 12), rand_range(-12, 12))
	hit_pitch = $AudioHit.pitch_scale
	turn_rate = rand_range(turn_rate_min, turn_rate_max)

func set_target(new_target: Mouse):
	target = new_target
	target_pos = target.get_bullet_target()
	
func _physics_process(delta):
	if is_instance_valid(target) and target.is_ready():
		target_pos = target.get_bullet_target() + target_offset
	look_at(target_pos)
	velocity = Vector2(speed, 0).rotated(rotation)
	position += velocity * delta
	$Sprite.global_rotation_degrees += turn_rate * delta
	# TODO this is framerate dependant
	# maybe Tween to target position instead?
	if position.distance_to(target_pos) < speed * delta * 2:
		hit_target()
#		print($Sprite.global_rotation_degrees)
#	else:
#		queue_free()

func hit_target():
	if !ready: return
	ready = false
	var blast: Blast = blast_scene.instance()
	blast.position = global_position
	blast.rotation = rotation
	get_parent().add_child(blast)
	if aoe:
		blast.start($Area2D/CollisionShape2D.shape.radius * 2.0)
		var targets = $Area2D.get_overlapping_areas()
		for t in targets:
			if t.get_parent() is Mouse && is_instance_valid(t.get_parent()):
				t.get_parent().on_hit(self)
	else:
		blast.start()
		if is_instance_valid(target):
			target.on_hit(self)
	emit_signal("hit", self)
	visible = false
	random_hit_audio()
	$AudioHit.pitch_scale = rand_range(hit_pitch - 0.2, hit_pitch + 0.2)
	$AudioHit.play()
	yield($AudioHit, "finished")
	queue_free()

func random_hit_audio():
	if sounds.size() == 0: return
	$AudioHit.stream = sounds[randi() % sounds.size()]

#func _on_Area2D_area_entered(area: Node2D):
#	if (area.get_parent() == target):
#		hit_target()
