extends Cat

func up_yarn():
	damage += 25
	spawn_position.scale = Vector2(0.6, 0.6)
	bullet_sprite.modulate = Color('#4147dd')
	bullet_scene = preload("res://scenes/BulletYarn.tscn")
