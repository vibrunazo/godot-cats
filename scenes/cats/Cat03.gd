extends Cat

class_name Cat3, "res://assets/cat03.png"

func _on_up2_pressed():
	var cost = 25
	if map_ref.coins < cost:
		return
	map_ref.add_coins(-cost)
	add_worth(cost)
	cooldown *= 0.7
	$Cooldown.wait_time = cooldown
