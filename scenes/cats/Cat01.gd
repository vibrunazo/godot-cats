extends Cat

func up_tower(value: float = 20):
	up_range(value)
	$BaseSprite.visible = true
	$BaseSprite.texture = preload("res://assets/scratchtower.png")
	$Turret.position.y = -30
	
func up_yarn(value: float = 25):
	damage += value
	spawn_position.scale = Vector2(0.6, 0.6)
	bullet_sprite.modulate = Color('#4147dd')
	bullet_scene = preload("res://scenes/BulletYarn.tscn")

func up_teacup(value: float = 25):
	damage += value
	spawn_position.scale = Vector2(1.0, 1.0)
	bullet_sprite.modulate = Color.white
	bullet_sprite.texture = preload("res://assets/teacup.png")
	bullet_sprite.offset.y = 8
	bullet_scene = preload("res://scenes/BulletTeacup.tscn")
