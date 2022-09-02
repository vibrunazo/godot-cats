extends Node2D

class_name Cat, "res://assets/cat01.png"
signal clicked

var aggro_list = []
var target: Mouse
var bullet_scene = preload("res://scenes/Bullet.tscn")
onready var spawn_position: Position2D = $Turret/SpawnPosition
onready var bullet_sprite: Sprite = $Turret/SpawnPosition/BulletSprite
enum FocusType {FURTHEST, HEALTH}
export var building = true
export var selected = true
export var cat_name = "Cat1"
export var damage = 10
export var aggro_range := 200.0
export var shot_speed = 400
export(FocusType) var focus = 0
var total_cost = 10
onready var el_UI = $UIroot/UI
onready var el_circle = $SelectRoot/SelectionCircle
onready var el_actions: Control = get_node("%CatActions")
onready var el_up1_button: CircleButton = get_node("%CatActions").get_node("%UpButton")
onready var el_up2_button: CircleButton = get_node("%CatActions").get_node("%Up2Button")
onready var el_del_button: CircleButton = get_node("%CatActions").get_node("%DeleteButton")
var SELECTION_SIZE := 400.0
var map_ref: Node2D = null
var cell_pos: Vector2 = Vector2(0, 0)


func init(map):
	map_ref = map
	
# Called when the node enters the scene tree for the first time.
func _ready():
	el_UI.visible = false
	total_cost = map_ref.data[cat_name]['cost']
	update_worth(total_cost)
	if selected:
		update_range(aggro_range)
		el_circle.visible = true
	else:
		el_circle.visible = false
	if !building:
		done_building()

func update_range(new_range):
	aggro_range = new_range
	$AggroRange/AggroShape.shape.radius = new_range
	var selection_scale = (aggro_range * 2.0) / SELECTION_SIZE
	$SelectRoot.scale = Vector2(selection_scale, selection_scale)
#	print("range is now %s. radius is %s" % [aggro_range, $AggroRange/AggroShape.shape.radius])
	
func done_building(new_cell = Vector2(0, 0)):
	building = false
	cell_pos = new_cell
	$AggroRange.monitoring = true
#	unselect()
	el_circle.visible = false
	$AnimationPlayer.play("idle")
	modulate = Color.white
	adjust_UI()

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
	if !building:
#		yield(get_tree().create_timer(0.5),"timeout")
		$UIAnimations.play("select")
		$UIroot/UI/CatActions/AnimationPlayer.play("start")
		el_circle.visible = true
	
func unselect():
	selected = false
	$UIAnimations.play("unselect", 0, 2)
#	el_UI.visible = false
#	get_node("%CatAction/AnimationPlayer").play("start")
	if !Global.DEBUG: return
	for m in aggro_list:
		var mouse: Mouse = m
		mouse.show_target_index(false)
		
func update_aggro_labels():
	if !Global.DEBUG: return
	var i := 0
	for m in aggro_list:
		var mouse: Mouse = m
		mouse.show_target_index(true, str(i))
		i += 1


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _physics_process(delta):
	if is_instance_valid(target):
		follow_target()
		
func follow_target():
	if !target or !is_instance_valid(target): return
	if !target.is_inside_tree() or !is_inside_tree(): return
	if !$Turret.is_inside_tree(): return
	var pos = target.global_position
	$Turret.look_at(pos)

func acquire_new_target(new_target: Mouse):
	target = new_target
	if !target.is_connected("killed", self, "_on_target_died"):
		target.connect("killed", self, "_on_target_died", [target])
	follow_target()
	if $Cooldown.time_left > 0:
		return
	shoot()
	$Cooldown.start()

func lose_aggro(mouse: Mouse):
	aggro_list.erase(mouse)
	if selected:
		mouse.show_target_index(false)
		update_aggro_labels()

func gain_aggro(mouse: Mouse):
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
	var best_score := 0
	var best: Mouse = aggro_list[0]
	for m in aggro_list:
		var mouse: Mouse = m
		if mouse.offset > best_score:
			best_score = mouse.offset
			best = mouse
	return best

func search_health() -> Mouse:
	var best_score := 0
	var best: Mouse = aggro_list[0]
	for m in aggro_list:
		var mouse: Mouse = m
		if mouse.health > best_score:
			best_score = mouse.health
			best = mouse
	return best

func shoot():
	if !target or !is_instance_valid(target):
		$Cooldown.stop()
		return
	var bullet = bullet_scene.instance()
#	get_tree().root.add_child(bullet)
#	get_tree().root.call_deferred("add_child", bullet)
	map_ref.get_node("Actors").call_deferred("add_child", bullet)
	bullet.position = spawn_position.global_position
	bullet.damage = damage
	bullet.speed = shot_speed
	bullet.set_target(target)
	play_attack_anim()

func play_attack_anim():
	$AnimationPlayer.stop(true)
	$AnimationPlayer.play("attack")
	yield($AnimationPlayer, "animation_finished")
	$AnimationPlayer.play("idle")
#	bullet_sprite.visible = false
#	yield(get_tree().create_timer(.4), "timeout")
#	bullet_sprite.visible = true

func update_worth(new_worth: int):
	total_cost = new_worth
	el_del_button.update_cost(get_delete_coins())

func add_worth(new_worth: int):
	update_worth(total_cost + new_worth)
	
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
	shoot()

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
	var cost = total_cost
	map_ref.add_coins(get_delete_coins())
	map_ref.remove_cat_at_cell(cell_pos)
	queue_free()

func on_map_coins_changed(coins: int):
	el_up1_button.set_state_from_coins(coins)
	el_up2_button.set_state_from_coins(coins)
