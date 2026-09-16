@icon("res://assets/cat02.png")
extends Cat

class_name Cat2


func _ready() -> void:
	super._ready()
	bullet_scene = preload("res://scenes/Bullet02.tscn")


func up_fireball(value: float = 25.0) -> void:
	damage = value
	shot_speed = 180
#	spawn_position.scale = Vector2(1.0, 1.0)
	bullet_sprite.modulate = Color.YELLOW
	$Turret/SpriteRoot/SpawnPosition/BulletSprite/BulletGlowSprite.modulate = Color(0.95, 0.8, 0.2, 0.5)
#	bullet_sprite.texture = preload("res://assets/yarn.png")
	bullet_scene = preload("res://scenes/BulletFire.tscn")
