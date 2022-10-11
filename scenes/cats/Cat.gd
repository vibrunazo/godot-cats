extends Node2D

class_name Cat, "res://assets/cat01.png"
# warning-ignore:unused_signal
signal clicked

var aggro_list = []
var target: Mouse
var locked_target: Mouse
var grabbed_target: Mouse
var bullet_scene = preload("res://scenes/BulletBasic.tscn")
enum FocusType {FURTHEST, HEALTH}
#export var building = true
export var selected = true
export var cat_name = "Cat1"
export var damage = 10
export var cooldown = 2.0
export var aggro_range := 200.0
export var shot_speed = 400
export var turn_speed: float = 3.5
export var attack_anim = "attack"
# Meows every X shots
export var meow_every = 0
export(FocusType) var focus = 0
var total_cost = 10
onready var spawn_position: Position2D = $"%SpawnPosition"
onready var bullet_sprite: Sprite = $"%SpawnPosition/BulletSprite"
onready var el_UI = $UIroot/UI
onready var el_circle = $SelectRoot/SelectionCircle
onready var el_actions: Control = get_node("%CatActions")
onready var el_up1_button: CircleButton = get_node("%CatActions").get_node("%UpButton")
onready var el_up2_button: CircleButton = get_node("%CatActions").get_node("%Up2Button")
onready var el_del_button: CircleButton = get_node("%CatActions").get_node("%DeleteButton")
onready var buttons: Array = [el_del_button, el_up1_button, el_up2_button]
onready var el_grab_l: Position2D = $"%grab_l"
onready var el_cat_tooltip: Tooltip = $"%CatTooltip"
var SELECTION_SIZE := 400.0
var map_ref: Node2D = null
var cell_pos: Vector2 = Vector2(0, 0)
enum State {BUILDING, READY, ATTACK, EAT}
var state: int = State.BUILDING


func init(map):
	map_ref = map
	
# Called when the node enters the scene tree for the first time.
func _ready():
	el_UI.visible = false
	$UIroot.visible = true
	$SelectRoot.visible = true
	$ClickArea.visible = true
	total_cost = map_ref.data[cat_name]['cost']
	update_worth(total_cost)
#	var full_name = GameData.cat_data[cat_name].full_name
#	var description = GameData.cat_data[cat_name].description
#	el_cat_tooltip.set_label(full_name, description)
	if selected:
		update_range(aggro_range)
		el_circle.visible = true
	else:
		el_circle.visible = false
	if !is_building():
		done_building()
	else:
		$AudioSpawn.play()

func is_building() -> bool:
	return state == State.BUILDING
	
func is_ready() -> bool:
	return state == State.READY

func update_range(new_range):
	aggro_range = new_range
	$AggroRange/AggroShape.shape.radius = new_range
	var selection_scale = (aggro_range * 2.0) / SELECTION_SIZE
	$SelectRoot.scale = Vector2(selection_scale, selection_scale)
#	print("range is now %s. radius is %s" % [aggro_range, $AggroRange/AggroShape.shape.radius])
	
func done_building(new_cell = Vector2(0, 0)):
	state = State.READY
	cell_pos = new_cell
	$AggroRange.monitoring = true
#	unselect()
	el_circle.visible = false
	$AnimationPlayer.play("idle")
	modulate = Color.white
	adjust_UI()
	register_action_buttons()
	$AudioSpawn.play()
	$AudioGrass.play()
	search_new_target()

# adjust action buttons positions so they don't stay off screen 
# if the Cat is close to screen borders
# called when done building
func adjust_UI():
	if cell_pos.x == 0:
		el_actions.rect_position.x += 200
		el_actions.rect_pivot_offset.x -= 200
		el_actions.get_node("HBoxContainer").rect_pivot_offset.x -= 200
	if cell_pos.x == map_ref.max_cell_x:
		el_actions.rect_position.x -= 200
		el_actions.rect_pivot_offset.x += 200
		el_actions.get_node("HBoxContainer").rect_pivot_offset.x += 200
	if cell_pos.y == map_ref.max_cell_y:
		el_actions.rect_position.y -= 250
		el_actions.rect_pivot_offset.y += 250
		el_actions.get_node("HBoxContainer").rect_pivot_offset.y += 250

func select():
	selected = true
	on_map_coins_changed(map_ref.coins)
	el_UI.visible = true
	update_aggro_labels()
	$AudioSpawn.play()
	if !is_building():
#		yield(get_tree().create_timer(0.5),"timeout")
		$UIAnimations.play("select")
		$UIroot/UI/CatActions/AnimationPlayer.play("start")
		el_circle.visible = true
#		show_cat_tooltip()
	
func unselect():
	selected = false
	$UIAnimations.play("unselect", 0, 2)
#	hide_cat_tooltip()
	if !Global.DEBUG: return
	for m in aggro_list:
		var mouse: Mouse = m
		mouse.show_target_index(false)

# updates the cat's tooltip
# with name, description and stats
func update_tooltip():
	var full_name = tr(GameData.cat_data[cat_name].full_name)
	var description = tr(GameData.cat_data[cat_name].description)
	description = (
		tr('cat_stats')
		% [damage, aggro_range / 200.0, cooldown] )
	el_cat_tooltip.set_label(full_name, description)

# called by map when cat is clicked
func show_tooltip(duration = -1):
	update_tooltip()
	el_cat_tooltip.show(duration)

func hide_tooltip():
	el_cat_tooltip.hide()

# connects what each action button does
# based on this Cat's actions tree
# updates their tooltips
# called when done building
func register_action_buttons():
	var actions = $Actions.get_children()
	var id = 0
	for b in buttons:
		var button: CircleButton = b
		var action: Action = actions[id]
		# warning-ignore:return_value_discarded
		button.connect("pressed", self, "action_pressed", [button])
		register_action_to_button(action, button)
		id += 1
	el_cat_tooltip.register_tooltip()
	update_tooltip()

func register_action_to_button(action: Action, button: CircleButton):
	button.action = action
	button.update_icon(action.icon, action.icon_size, action.icon_tint)
	if action.cost > 0:
		button.update_cost(action.cost)
	else:
		button.update_cost(get_delete_coins())
	button.el_tooltip.set_label(action.action_name, action.description)
	button.register_tooltip()

func update_aggro_labels():
	if !Global.DEBUG: return
	var i := 0
	for m in aggro_list:
		var mouse: Mouse = m
		mouse.show_target_index(true, str(i))
		i += 1

# upgrades range
# value in centimeters 
# 220 pixels in game is 110 cm
func up_range(value: float):
	update_range(aggro_range + value * 2.0)

func up_damage(value):
	damage += value

# upgrades cooldown
# value in percentage,
# ie, value of 30 reduces cooldown by 30%
func up_cooldown(value: float):
	cooldown *= (1 - value/100.0)
	$Cooldown.wait_time = cooldown

func action_pressed(button: CircleButton):
	var action = button.action
	print('action pressed %s' % action)
	var cost = action.cost
	if map_ref.coins < cost || cost < 0:
		return
	map_ref.add_coins(-cost)
	add_worth(cost)
	var children = action.get_children()
	print('children of %s are: %s' % [action, children])
	if children.size() > 0:
		register_action_to_button(children[0], button)
	else:
		button.hide()
	callv(action.method, action.binds)
	update_tooltip()

func _physics_process(_delta):
	if is_instance_valid(target):
		if !is_ready():
			follow_target()
		else:
			attack()
		
func follow_target():
	if !target or !is_instance_valid(target): return
	if !is_ready() and state != State.ATTACK: return
#	if state == State.EAT: return
	if !target.is_inside_tree() or !is_inside_tree(): return
	if !$Turret.is_inside_tree(): return
	var pos := target.global_position
	var target_vector: Vector2 = pos - global_position
	var target_rot: float = target_vector.angle()
	var target_tran: Transform2D = Transform2D(target_rot, $Turret.global_position)
	$Turret.global_transform = $Turret.global_transform.interpolate_with(target_tran, turn_speed * get_physics_process_delta_time())
#	$Turret.global_rotation = lerp($Turret.global_rotation, target_rot, 1.5 * get_physics_process_delta_time())
#	$Turret.look_at(pos)

func acquire_new_target(new_target: Mouse):
	target = new_target
	if !target.is_connected("killed", self, "_on_target_died"):
# warning-ignore:return_value_discarded
		target.connect("killed", self, "_on_target_died", [target])
	follow_target()
	if $Cooldown.time_left > 0:
		return
	attack()
	$Cooldown.stop()
	$Cooldown.wait_time = cooldown
	$Cooldown.start(cooldown)

func lose_aggro(mouse: Mouse):
	aggro_list.erase(mouse)
	if selected:
		mouse.show_target_index(false)
		update_aggro_labels()

func gain_aggro(mouse: Mouse):
	if !mouse.is_ready(): return
	aggro_list.append(mouse)
	if selected:
		update_aggro_labels()
	
func _on_target_died(dead_mouse: Mouse):
#	print('target died')
	lose_aggro(dead_mouse)
	if dead_mouse == target:
		target = null
	search_new_target()

func search_new_target():
#	print(aggro_list)
	if aggro_list.size() == 0: return
	var best: Mouse = aggro_list[0]
	if focus == FocusType.FURTHEST:
		best = search_furthest()
	if focus == FocusType.HEALTH:
		best = search_health()
#	print('best is %s' % best)
	acquire_new_target(best)

func search_furthest() -> Mouse:
	var best_score: float = 0.0
	var best: Mouse = aggro_list[0]
	for m in aggro_list:
		var mouse: Mouse = m
		if !mouse.is_ready(): continue
		if mouse.offset > best_score:
			best_score = mouse.offset
			best = mouse
	return best

func search_health() -> Mouse:
	var best_score: float = 0.0
	var best: Mouse = aggro_list[0]
	for m in aggro_list:
		var mouse: Mouse = m
		if !mouse.is_ready(): continue
		if mouse.health > best_score:
			best_score = mouse.health
			best = mouse
	return best

func attack():
	if !target or !is_instance_valid(target) or !target.is_ready() or !is_ready():
		$Cooldown.stop()
		return
#	if is_instance_valid(locked_target) and locked_target.is_grabbed() and el_grab_l.get_child_count() > 0:
#		locked_target.on_finished_eaten()
	locked_target = target
	play_attack_anim()
	$AudioShoot.pitch_scale = rand_range(0.8, 1.2)
	$AudioShoot.play()
	if meow_every > 0 and randi() % meow_every == 0:
		$AudioSpawn.play()
		
func shoot():
	var bullet = bullet_scene.instance()
	map_ref.get_node("Actors").call_deferred("add_child", bullet)
	bullet.position = spawn_position.global_position
	bullet.damage = damage
	bullet.speed = shot_speed
	bullet.set_target(locked_target)

func hit_target():
	if !locked_target or !is_instance_valid(locked_target) or !locked_target.is_ready():
		return
	locked_target.on_hit(self)

# grabs a target
# called by the animation when it gets to the appropriate frame
func grab_target():
	if !locked_target or !is_instance_valid(locked_target) or !locked_target.is_ready(): 
		$Cooldown.stop()
		$Cooldown.start(0.8)
		$Cooldown.wait_time = cooldown
#		search_new_target()
		return
	if is_instance_valid(grabbed_target):
		grabbed_target.on_finished_eaten()
	state = State.EAT
	grabbed_target = locked_target
	var rot = locked_target.global_rotation
	locked_target.on_get_grabbed(self)
	locked_target.get_parent().remove_child(locked_target)
	el_grab_l.add_child(locked_target)
	locked_target.position = Vector2(0, 0)
	locked_target.global_rotation = rot
	target = null
	$AudioGrass.pitch_scale = 3.0
	$AudioGrass.play()

func play_attack_anim():
	follow_target()
	$AnimationPlayer.stop(true)
	$AnimationPlayer.play(attack_anim)
	state = State.ATTACK
	yield($AnimationPlayer, "animation_finished")
	if is_instance_valid(grabbed_target):
#		print('has grab %s' % $AnimationPlayer.assigned_animation)
		$AnimationPlayer.play("eat")
	else:
#		print('no grab %s' % $AnimationPlayer.assigned_animation)
		$AnimationPlayer.play("idle")

func on_eat_finished():
	if is_instance_valid(grabbed_target):
		grabbed_target.on_finished_eaten()
#	print('eat finished %s' % $AnimationPlayer.assigned_animation)
	grabbed_target = null
	if !is_ready():
		$AnimationPlayer.play("sleeping")
		yield(get_tree().create_timer(0.35), "timeout")
		$AudioPurr.play()
	else:
		$AnimationPlayer.play("idle")

# updates how much the Cat is worth 
# based on the costs of all upgrades
# higher worth means more coins back when the Cat is deleted
func update_worth(new_worth: int):
	total_cost = new_worth
	el_del_button.update_cost(get_delete_coins())

func add_worth(new_worth: int):
	update_worth(total_cost + new_worth)
	
# returns how many coins you'd get for deleting this cat
# increases as you get more upgrades
func get_delete_coins() -> int:
	return int(total_cost * 0.8)

func _on_AggroRange_area_entered(area: Node):
	if !area.get_parent().is_in_group("mice"):
		return
	var mouse: Mouse = area.get_parent()
	gain_aggro(mouse)
	if !target:
		search_new_target()
#		acquire_new_target(mouse)
#	print(aggro_list)

func _on_AggroRange_area_exited(area: Node):
	if !area.get_parent().is_in_group("mice"):
		return
	var mouse: Mouse = area.get_parent()
	lose_aggro(mouse)
	if mouse == target:
		target = null
		search_new_target()
	
#	print(aggro_list)


func _on_Cooldown_timeout():
	if $AnimationPlayer.current_animation == "sleeping":
		$AnimationPlayer.play("idle")
	state = State.READY
	if !is_instance_valid(target):
		$Cooldown.stop()
	$Cooldown.wait_time = cooldown
#	print('cat cooldown up')

func _on_up_pressed():
	var cost = 5
	if map_ref.coins < cost:
		return
	map_ref.add_coins(-cost)
	add_worth(cost)
	update_range(aggro_range + 20.0)

func _on_up2_pressed():
	var cost = 20
	if map_ref.coins < cost:
		return
	map_ref.add_coins(-cost)
	add_worth(cost)
	damage += 10

func _on_delete_pressed():
#	var cost = total_cost
	map_ref.add_coins(get_delete_coins())
	map_ref.remove_cat_at_cell(cell_pos)
	queue_free()

func on_map_coins_changed(coins: int):
	el_up1_button.set_state_from_coins(coins)
	el_up2_button.set_state_from_coins(coins)
