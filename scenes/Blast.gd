extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func start(size: float):
	print('so anyway I started blasting')
	$Sprite.scale = Vector2(size / 200, size / 200)
	$AnimationPlayer.play("boom")
	yield($AnimationPlayer, "animation_finished")
	queue_free()
