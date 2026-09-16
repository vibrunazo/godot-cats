@icon("res://assets/ball.png")
extends Node2D

class_name Bullet

signal hit

@export var speed: int = 400
@export var damage: float = 10.0
@export var aoe: bool = false
@export var turn_rate_min: float = 0.0
@export var turn_rate_max: float = 0.0
@export var sounds: Array[AudioStream] = []
@export var blast_scene: PackedScene
var target: Mouse = null: set = set_target
var target_offset: Vector2 = Vector2(0, 0)
var target_pos: Vector2 = Vector2(0, 0)
var can_hit: bool = true
#var blast_scene = preload(blast)
#var blast_scene: PackedScene = preload("res://scenes/Blast.tscn")
var hit_pitch: float = 1.0
var velocity: Vector2 = Vector2.ZERO
var turn_rate: float = 0.0


func _ready() -> void:
	target_offset = Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0))
	hit_pitch = $AudioHit.pitch_scale
	turn_rate = randf_range(turn_rate_min, turn_rate_max)

func set_target(new_target: Mouse) -> void:
	target = new_target
	target_pos = target.get_bullet_target()

func _physics_process(delta: float) -> void:
	if is_instance_valid(target) and target.is_ready():
		target_pos = target.get_bullet_target() + target_offset
	look_at(target_pos)
	velocity = Vector2(speed, 0).rotated(rotation)
	position += velocity * delta
	$Sprite2D.global_rotation_degrees += turn_rate * delta
	# TODO this is framerate dependant
	# maybe Tween to target position instead?
	if position.distance_to(target_pos) < speed * delta * 2.0:
		hit_target()
#		print($Sprite.global_rotation_degrees)
#	else:
#		queue_free()

func hit_target() -> void:
	if !can_hit: return
	can_hit = false
	var blast := blast_scene.instantiate() as Blast
	blast.position = global_position
	blast.rotation = rotation
	get_parent().add_child(blast)
	if aoe:
		blast.start($Area2D/CollisionShape2D.shape.radius * 2.0)
		var targets: Array[Area2D] = $Area2D.get_overlapping_areas()
		for t: Area2D in targets:
			if t.get_parent() is Mouse && is_instance_valid(t.get_parent()):
				(t.get_parent() as Mouse).on_hit(self)
	else:
		blast.start()
		if is_instance_valid(target):
			target.on_hit(self)
	emit_signal("hit", self)
	visible = false
	random_hit_audio()
	$AudioHit.pitch_scale = randf_range(hit_pitch - 0.2, hit_pitch + 0.2)
	$AudioHit.play()
	await $AudioHit.finished
	queue_free()

func random_hit_audio() -> void:
	if sounds.size() == 0: return
	$AudioHit.stream = sounds[randi() % sounds.size()]

#func _on_Area2D_area_entered(area: Node2D):
#	if (area.get_parent() == target):
#		hit_target()
