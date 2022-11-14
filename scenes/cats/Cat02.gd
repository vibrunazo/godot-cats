extends "res://scenes/cats/Cat.gd"

class_name Cat2, "res://assets/cat02.png"


# Called when the node enters the scene tree for the first time.
func _ready():
	._ready()
	bullet_scene = preload("res://scenes/Bullet02.tscn")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func up_fire(value: float = 25):
	damage += value
	shot_speed = 280
#	spawn_position.scale = Vector2(1.0, 1.0)
	bullet_sprite.modulate = Color.white
	$Turret/SpriteRoot/SpawnPosition/BulletSprite/BulletGlowSprite.modulate = Color(0.95, 0.8, 0.2, 0.5)
#	bullet_sprite.texture = preload("res://assets/yarn.png")
	bullet_scene = preload("res://scenes/BulletFire.tscn")
