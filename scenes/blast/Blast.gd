extends Node2D

class_name Blast

export var start_size := 0.0
export var anim: String = 'boom'
export var rand_rot: bool = true
onready var el_sprite_root: Node2D = $SpriteRoot
#onready var el_sprite: Sprite = $"%Sprite"

func start(size: float = start_size):
	if size > 0:
		el_sprite_root.scale = Vector2(size / 200.0, size / 200.0)
	if rand_rot:
		rotation_degrees = rand_range(0, 360)
	$AnimationPlayer.play(anim)
	yield($AnimationPlayer, "animation_finished")
	queue_free()
