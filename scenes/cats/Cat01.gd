extends Cat

func up_yarn(value: float = 25):
	damage += value
	spawn_position.scale = Vector2(0.6, 0.6)
	bullet_sprite.modulate = Color('#4147dd')
	bullet_scene = preload("res://scenes/BulletYarn.tscn")
