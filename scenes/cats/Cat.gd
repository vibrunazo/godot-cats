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
onready var el_UI = $Node2D/UI
var SELECTION_SIZE := 400.0
var map_ref: Node2D = null
var cell_pos: Vector2 = Vector2(0, 0)


func init(map):
	map_ref = map
	
# Called when the node enters the scene tree for the first time.
func _ready():
	el_UI.visible = false
	if selected:
		update_range(aggro_range)
		$SelectionCircle.visible = true
	else:
		$SelectionCircle.visible = false
	if !building:
		done_building()

func update_range(new_range):
	aggro_range = new_range
	$AggroRange/AggroShape.shape.radius = new_range
	var selection_scale = (aggro_range * 2.0) / SELECTION_SIZE
	$SelectionCircle.scale = Vector2(selection_scale, selection_scale)
#	$SelectionCircle.scale = Vector2(2,2)
	print("range is now %s. radius is %s" % [aggro_range, $AggroRange/AggroShape.shape.radius])
	
func done_building(new_cell = Vector2(0, 0)):
	building = false
	cell_pos = new_cell
	$AggroRange.monitoring = true
	unselect()
	$AnimationPlayer.play("idle")
	modulate = Color.white
	
func select():
	selected = true
	on_map_coins_changed(map_ref.coins)
	$SelectionCircle.visible = true
	if !building:
		el_UI.visible = true
		$Node2D/UI/CatActions/AnimationPlayer.play("start")
	update_aggro_labels()
	
func unselect():
	selected = false
	$SelectionCircle.visible = false
	el_UI.visible = false
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
	if (target):
		follow_target()
		
func follow_target():
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
	get_tree().root.call_deferred("add_child", bullet)
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
	update_range(aggro_range + 20.0)
	

func _on_up2_pressed():
	var cost = 20
	if map_ref.coins < cost:
		return
	map_ref.add_coins(-cost)
	damage += 10

func _on_delete_pressed():
	var cost = map_ref.data[cat_name]['cost']
	map_ref.add_coins(int(cost * 0.75))
	map_ref.remove_cat_at_cell(cell_pos)
	queue_free()

func on_map_coins_changed(coins: int):
	if coins < 5:
#		$Node2D/UI/CatActions/HBoxContainer/UpButton.disabled = true
		$Node2D/UI/CatActions.get_node("%UpButton").disabled = true
#		get_node("%UpButton").disabled = true
	else:
		$Node2D/UI/CatActions/HBoxContainer/UpButton.disabled = false
	if coins < 20:
		$Node2D/UI/CatActions/HBoxContainer/Up2Button.disabled = true
	else:
		$Node2D/UI/CatActions/HBoxContainer/Up2Button.disabled = false
