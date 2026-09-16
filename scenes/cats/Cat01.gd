extends Cat


## House upgrade: longer range and a visible house base.
func up_house(value: float = 10.0) -> void:
	up_range(value)
	$BaseSprite.visible = true
	$BaseSprite.texture = preload("res://assets/scratchhouse.png")
	$Turret.position.y = -13.0


## Tower upgrade: even longer range and a tall tower base.
func up_tower(value: float = 20.0) -> void:
	up_range(value)
	$BaseSprite.visible = true
	$BaseSprite.texture = preload("res://assets/scratchtower.png")
	$Turret.position.y = -33.0


## Yarn upgrade: harder hits with slower yarn-ball bullets.
func up_yarn(value: float = 25.0) -> void:
	damage += value
	shot_speed = 280
	spawn_position.scale = Vector2(1.0, 1.0)
	bullet_sprite.modulate = Color.WHITE
	bullet_sprite.texture = preload("res://assets/yarn.png")
	bullet_scene = preload("res://scenes/BulletYarn.tscn")


## Teacup upgrade: harder hits with fast teacup bullets.
func up_teacup(value: float = 25.0) -> void:
	damage += value
	shot_speed = 400
	spawn_position.scale = Vector2(1.0, 1.0)
	bullet_sprite.modulate = Color.WHITE
	bullet_sprite.texture = preload("res://assets/teacup.png")
	bullet_sprite.offset.y = 8.0
	bullet_scene = preload("res://scenes/BulletTeacup.tscn")
