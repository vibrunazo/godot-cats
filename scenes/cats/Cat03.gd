extends Cat

class_name Cat3, "res://assets/cat03.png"

func _ready():
	action_names = ['action_delete', 'action_range', 'action_sleep']
	action_descs = ['action_delete_desc', 'action_range_desc', 'action_sleep_desc']

func _on_up2_pressed():
	var cost = 25
	if map_ref.coins < cost:
		return
	map_ref.add_coins(-cost)
	add_worth(cost)
	cooldown *= 0.7
	$Cooldown.wait_time = cooldown
