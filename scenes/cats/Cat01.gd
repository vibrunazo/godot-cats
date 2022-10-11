extends Cat

func up_tower(value: float = 20):
	up_range(value)
	$BaseSprite.visible = true
	$BaseSprite.texture = preload("res://assets/scratchtower.png")
	$Turret.position.y = -30
	
func up_yarn(value: float = 25):
	damage += value
	shot_speed = 280
	spawn_position.scale = Vector2(1.0, 1.0)
	bullet_sprite.modulate = Color.white
	bullet_sprite.texture = preload("res://assets/yarn.png")
	bullet_scene = preload("res://scenes/BulletYarn.tscn")

func up_teacup(value: float = 25):
	damage += value
	shot_speed = 400
	spawn_position.scale = Vector2(1.0, 1.0)
	bullet_sprite.modulate = Color.white
	bullet_sprite.texture = preload("res://assets/teacup.png")
	bullet_sprite.offset.y = 8
	bullet_scene = preload("res://scenes/BulletTeacup.tscn")
