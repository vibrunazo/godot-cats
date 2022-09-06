extends Node2D

class_name Bullet, "res://assets/ball.png"

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var speed = 400
export var damage = 10
export var aoe = false
export(Array, AudioStream) var sounds: Array
var target: Mouse = null setget set_target
var target_offset: Vector2 = Vector2(0, 0)
var target_pos: Vector2 = Vector2(0, 0)
var ready = true
var blast_scene = preload("res://scenes/Blast.tscn")
var hit_pitch: float = 1


# Called when the node enters the scene tree for the first time.
func _ready():
	target_offset = Vector2(rand_range(-20, 20), rand_range(-20, 20))
	$AudioSpawn.pitch_scale = rand_range(0.8, 1.2)
	$AudioSpawn.play()
	hit_pitch = $AudioHit.pitch_scale
#	look_at(Vector2(400, 200))
#	rotation_degrees = 60

func set_target(new_target: Mouse):
	target = new_target
	target_pos = target.get_bullet_target()
	
func _physics_process(delta):
	if is_instance_valid(target):
		target_pos = target.get_bullet_target() + target_offset
	look_at(target_pos)
	position += Vector2(speed * delta, 0).rotated(rotation)
	$Sprite.global_rotation_degrees = 0
	if position.distance_to(target_pos) < speed * delta * 2:
		hit_target()
#		print($Sprite.global_rotation_degrees)
#	else:
#		queue_free()

func hit_target():
	if !ready: return
	ready = false
	if aoe:
		var targets = $Area2D.get_overlapping_areas()
		for t in targets:
			if t.get_parent() is Mouse && is_instance_valid(t.get_parent()):
				t.get_parent().on_hit(self)
		var blast = blast_scene.instance()
		blast.position = global_position
		get_parent().add_child(blast)
		blast.start($Area2D/CollisionShape2D.shape.radius)
	else:
		if is_instance_valid(target):
			target.on_hit(self)
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
