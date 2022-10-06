extends Cat

func _on_up2_pressed():
	var cost = 15
	if map_ref.coins < cost:
		return
	map_ref.add_coins(-cost)
	add_worth(cost)
	damage += 25
	spawn_position.scale = Vector2(0.6, 0.6)
	bullet_sprite.modulate = Color('#4147dd')
	bullet_scene = preload("res://scenes/BulletYarn.tscn")
	el_up2_button.hide()
