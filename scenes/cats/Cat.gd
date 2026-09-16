@icon("res://assets/cat01.png")
extends Node2D

class_name Cat
@warning_ignore("unused_signal")
signal clicked
signal shot
signal cat_deselect
signal cat_select

var aggro_list: Array[Mouse] = []
var target: Mouse
var locked_target: Mouse
var grabbed_target: Mouse
var bullet_scene: PackedScene = preload("res://scenes/BulletBasic.tscn")
enum FocusType {FURTHEST, HEALTH}
#export var building = true
@export var selected: bool = true
@export var cat_name: String = "Cat1"
@export var damage: float = 10.0
@export var cooldown: float = 2.0
@export var aggro_range := 200.0
@export var shot_speed: int = 400
@export var turn_speed: float = 3.5
@export var attack_anim: String = "attack"
# Meows every X shots
@export var meow_every: int = 0
@export var focus: FocusType = FocusType.FURTHEST
var total_cost: int = 10
@onready var spawn_position: Marker2D = $"%SpawnPosition"
@onready var bullet_sprite: Sprite2D = $"%SpawnPosition/BulletSprite"
@onready var el_UI: Control = $UIroot/UI
@onready var el_circle: Node2D = $SelectRoot/SelectionCircle
@onready var el_actions: Control = get_node("%CatActions")
@onready var el_up1_button: CircleButton = get_node("%CatActions").get_node("%UpButton")
@onready var el_up2_button: CircleButton = get_node("%CatActions").get_node("%Up2Button")
@onready var el_del_button: CircleButton = get_node("%CatActions").get_node("%DeleteButton")
@onready var buttons: Array[CircleButton] = [el_del_button, el_up1_button, el_up2_button]
@onready var el_grab_l: Marker2D = $"%grab_l"
@onready var el_cat_tooltip: Tooltip = $"%CatTooltip"
var SELECTION_SIZE := 400.0
var map_ref: Map = null
var cell_pos: Vector2i = Vector2i(0, 0)
enum State {BUILDING, READY, ATTACK, EAT, DELETED}
var state: int = State.BUILDING


func init(map_arg: Map) -> void:
	map_ref = map_arg

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	el_UI.visible = false
	$UIroot.visible = true
	$SelectRoot.visible = true
	$ClickArea.visible = true
	total_cost = int(map_ref.data[cat_name]['cost'])
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

func update_range(new_range: float) -> void:
	aggro_range = new_range
	$AggroRange/AggroShape.shape.radius = new_range
	var selection_scale: float = (aggro_range * 2.0) / SELECTION_SIZE
	$SelectRoot.scale = Vector2(selection_scale, selection_scale)
#	print("range is now %s. radius is %s" % [aggro_range, $AggroRange/AggroShape.shape.radius])
	
func done_building(new_cell: Vector2i = Vector2i(0, 0)) -> void:
	state = State.READY
	cell_pos = new_cell
	$AggroRange.monitoring = true
#	unselect()
	el_circle.visible = false
	$AnimationPlayer.play("idle")
	modulate = Color.WHITE
	adjust_UI()
	register_action_buttons()
	$AudioSpawn.play()
	$AudioGrass.play()
	search_new_target()

# adjust action buttons positions so they don't stay off screen 
# if the Cat is close to screen borders
# called when done building
func adjust_UI() -> void:
	var hbox: Control = el_actions.get_node("HBoxContainer")
	var margin_box: Control = el_actions.get_node("MarginContainer")
	# at left-most column
	if cell_pos.x == 0:
		el_actions.position.x += 200
		el_actions.pivot_offset.x -= 200
		hbox.pivot_offset.x -= 200
	# at right-most column
	if cell_pos.x == map_ref.max_cell_x:
		el_actions.position.x -= 200
		el_actions.pivot_offset.x += 200
		hbox.pivot_offset.x += 200
		margin_box.position.x -= 200
		# and not at the top
		if cell_pos.y != 0:
			margin_box.position.y -= 100
	# at the bottom
	if cell_pos.y == map_ref.max_cell_y:
		el_actions.position.y -= 250
		el_actions.pivot_offset.y += 250
		hbox.pivot_offset.y += 250
	# at bottom 3 rows
	if cell_pos.y > map_ref.max_cell_y - 3:
		el_cat_tooltip.position.x -= 350

func select() -> void:
	selected = true
	on_map_coins_changed(map_ref.coins)
	el_UI.visible = true
	update_aggro_labels()
	$AudioSpawn.play()
	if !is_building():
#		yield(get_tree().create_timer(0.5),"timeout")
		$UIAnimations.play("select", -1, 1 / Engine.time_scale)
		$UIroot/UI/CatActions/AnimationPlayer.play("start")
		el_circle.visible = true
#		show_cat_tooltip()
	
func deselect() -> void:
	selected = false
	$UIAnimations.play("deselect", -1, 2 / Engine.time_scale)
#	hide_cat_tooltip()
	if !Global.DEBUG: return
	for m: Mouse in aggro_list:
		m.show_target_index(false)

# updates the cat's tooltip
# with name, description and stats
func update_tooltip() -> void:
	var full_name: String = tr(GameData.cat_data[cat_name].full_name)
	var description: String = tr(GameData.cat_data[cat_name].description)
	description = (
		tr('cat_stats')
		% [damage, aggro_range / 200.0, cooldown] )
	el_cat_tooltip.set_label(full_name, description)

# called by map when cat is clicked
func show_tooltip(duration: float = -1.0) -> void:
	update_tooltip()
	el_cat_tooltip.show_tooltip(duration)

func hide_tooltip() -> void:
	el_cat_tooltip.hide_tooltip()

# connects what each action button does
# based on this Cat's actions tree
# updates their tooltips
# called when done building
func register_action_buttons() -> void:
	var actions: Array[Node] = $Actions.get_children()
	var id: int = 0
	for b: CircleButton in buttons:
		var button: CircleButton = b
		var action: Action = actions[id] as Action
		button.connect("pressed", Callable(self, "action_pressed").bind(button))
		register_action_to_button(action, button)
		id += 1
	el_cat_tooltip.register_tooltip()
	update_tooltip()

func register_action_to_button(action: Action, button: CircleButton) -> void:
	button.action = action
	button.update_icon(action.icon, action.icon_size, action.icon_tint)
	if action.cost > 0:
		button.update_cost(action.cost)
	else:
		button.update_cost(-get_delete_coins())
	button.el_tooltip.set_label(action.action_name, action.description)
	button.register_tooltip()

func update_aggro_labels() -> void:
	if !Global.DEBUG: return
	var i: int = 0
	for m: Mouse in aggro_list:
		m.show_target_index(true, str(i))
		i += 1

# delete action has been confirmed
func on_delete_confirm() -> void:
	map_ref.add_coins(get_delete_coins())
	map_ref.remove_cat_at_cell(cell_pos)
	queue_free()
	state = State.DELETED

# upgrades range
# value in centimeters
# 220 pixels in game is 110 cm
func up_range(value: float) -> void:
	update_range(aggro_range + value * 2.0)

func up_damage(value: float) -> void:
	damage += value

# upgrades cooldown
# value in percentage,
# ie, value of 30 reduces cooldown by 30%
func up_cooldown(value: float) -> void:
	cooldown *= (1 - value / 100.0)
	$Cooldown.wait_time = cooldown

# an action button was pressed (upgrade or delete)
# run common code between all actions
# action specific code is run in the end by the callv()
func action_pressed(button: CircleButton) -> void:
	var action: Action = button.action
	print('action pressed %s' % action)
	if Config.confirm:
		action_popup(action, button)
	else:
		on_action_confirm(action, button)

func action_popup(action: Action, button: CircleButton) -> void:
	var popup_scene: PackedScene = load("res://scenes/UI/CatDialog.tscn") as PackedScene
	var popup := popup_scene.instantiate() as CatDialog
	map_ref.get_node("UI/Tooltips").add_child(popup)
#	var full_name = tr(GameData.cat_data[cat_name].full_name)
#	popup.set_text(tr('menu_delete').format([full_name, get_delete_coins()]))
	popup.set_popup_title(tr(action.action_name))
	popup.set_popup_text(tr(action.description))
	popup.set_popup_icon(action.icon)
	emit_signal("cat_deselect")
	popup.connect("confirmed", Callable(self, "on_action_confirm").bind(action, button))
	# NOTE: Godot 3 Popup.popup_hide became Window.visibility_changed in Godot 4;
	# on_action_canceled ignores the shown notification and acts on hide.
	popup.connect("visibility_changed", Callable(self, "on_action_canceled").bind(popup))
	popup.popup_centered()

# action popup confirmed. Call method to apply upgrade
func on_action_confirm(action: Action, button: CircleButton) -> void:
	callv(action.method, action.binds)
	var cost: int = action.cost
	if map_ref.coins < cost || cost < 0:
		return
	map_ref.add_coins(-cost)
	add_worth(cost)
	var children: Array[Node] = action.get_children()
	print('children of %s are: %s' % [action, children])
	if children.size() > 0:
		register_action_to_button(children[0] as Action, button)
	else:
		button.hide()
	update_tooltip()

func _physics_process(_delta: float) -> void:
	if is_instance_valid(target):
		if !is_ready():
			follow_target()
		else:
			attack()

func follow_target() -> void:
	if !target or !is_instance_valid(target): return
	if !is_ready() and state != State.ATTACK: return
#	if state == State.EAT: return
	if !target.is_inside_tree() or !is_inside_tree(): return
	if !$Turret.is_inside_tree(): return
	var pos: Vector2 = target.global_position
	var target_vector: Vector2 = pos - global_position
	var target_rot: float = target_vector.angle()
	var target_tran: Transform2D = Transform2D(target_rot, $Turret.global_position)
	$Turret.global_transform = $Turret.global_transform.interpolate_with(target_tran, turn_speed * get_physics_process_delta_time())
#	$Turret.global_rotation = lerp($Turret.global_rotation, target_rot, 1.5 * get_physics_process_delta_time())
#	$Turret.look_at(pos)

func acquire_new_target(new_target: Mouse) -> void:
	target = new_target
	if !target.is_connected("killed", Callable(self, "_on_target_died")):
		target.connect("killed", Callable(self, "_on_target_died").bind(target))
	follow_target()
	if $Cooldown.time_left > 0:
		return
	attack()
	$Cooldown.stop()
	$Cooldown.wait_time = cooldown
	$Cooldown.start(cooldown)

func lose_aggro(mouse: Mouse) -> void:
	aggro_list.erase(mouse)
	if selected:
		mouse.show_target_index(false)
		update_aggro_labels()

func gain_aggro(mouse: Mouse) -> void:
	if !mouse.is_ready(): return
	aggro_list.append(mouse)
	if selected:
		update_aggro_labels()

func _on_target_died(dead_mouse: Mouse) -> void:
	lose_aggro(dead_mouse)
	if dead_mouse == target:
		target = null
	search_new_target()

func search_new_target() -> void:
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
	for m: Mouse in aggro_list:
		if !m.is_ready(): continue
		if m.progress > best_score:
			best_score = m.progress
			best = m
	return best

func search_health() -> Mouse:
	var best_score: float = 0.0
	var best: Mouse = aggro_list[0]
	for m: Mouse in aggro_list:
		if !m.is_ready(): continue
		if m.health > best_score:
			best_score = m.health
			best = m
	return best

func attack() -> void:
	if !target or !is_instance_valid(target) or !target.is_ready() or !is_ready():
		$Cooldown.stop()
		return
#	if is_instance_valid(locked_target) and locked_target.is_grabbed() and el_grab_l.get_child_count() > 0:
#		locked_target.on_finished_eaten()
	locked_target = target
	play_attack_anim()
	$AudioShoot.pitch_scale = randf_range(0.8, 1.2)
	$AudioShoot.play()
	if meow_every > 0 and randi() % meow_every == 0:
		$AudioSpawn.play()

func shoot() -> void:
	var bullet := bullet_scene.instantiate() as Bullet
	map_ref.get_node("Actors").call_deferred("add_child", bullet)
	bullet.position = spawn_position.global_position
	bullet.damage = damage
	bullet.speed = shot_speed
	bullet.set_target(locked_target)
	emit_signal("shot", bullet)

func hit_target() -> void:
	if !locked_target or !is_instance_valid(locked_target) or !locked_target.is_ready():
		return
	locked_target.on_hit(self)

# grabs a target
# called by the animation when it gets to the appropriate frame
func grab_target() -> void:
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
	var rot: float = locked_target.global_rotation
	locked_target.on_get_grabbed(self)
	locked_target.get_parent().remove_child(locked_target)
	el_grab_l.add_child(locked_target)
	locked_target.position = Vector2(0, 0)
	locked_target.global_rotation = rot
	target = null
	$AudioGrass.pitch_scale = 3.0
	$AudioGrass.play()

func play_attack_anim() -> void:
	follow_target()
	$AnimationPlayer.stop(true)
	$AnimationPlayer.play(attack_anim)
	state = State.ATTACK
	await $AnimationPlayer.animation_finished
	if is_instance_valid(grabbed_target):
		$AnimationPlayer.play("eat")
	else:
		$AnimationPlayer.play("idle")

func on_eat_finished() -> void:
	if is_instance_valid(grabbed_target):
		grabbed_target.on_finished_eaten()
	grabbed_target = null
	if !is_ready():
		$AnimationPlayer.play("sleeping")
		await get_tree().create_timer(0.35).timeout
		$AudioPurr.play()
	else:
		$AnimationPlayer.play("idle")

# updates how much the Cat is worth 
# based on the costs of all upgrades
# higher worth means more coins back when the Cat is deleted
func update_worth(new_worth: int) -> void:
	total_cost = new_worth
	el_del_button.update_cost(-get_delete_coins())

func add_worth(new_worth: int) -> void:
	update_worth(total_cost + new_worth)
	
# returns how many coins you'd get for deleting this cat
# increases as you get more upgrades
func get_delete_coins() -> int:
	return int(total_cost * 0.8)

func _on_AggroRange_area_entered(area: Area2D) -> void:
	if !area.get_parent().is_in_group("mice"):
		return
	var mouse: Mouse = area.get_parent() as Mouse
	gain_aggro(mouse)
	if !target:
		search_new_target()
#		acquire_new_target(mouse)
#	print(aggro_list)

func _on_AggroRange_area_exited(area: Area2D) -> void:
	if !area.get_parent().is_in_group("mice"):
		return
	var mouse: Mouse = area.get_parent() as Mouse
	lose_aggro(mouse)
	if mouse == target:
		target = null
		search_new_target()
	
#	print(aggro_list)


func _on_Cooldown_timeout() -> void:
	if $AnimationPlayer.current_animation == "sleeping":
		$AnimationPlayer.play("idle")
	state = State.READY
	if !is_instance_valid(target):
		$Cooldown.stop()
	$Cooldown.wait_time = cooldown
#	print('cat cooldown up')

#func _on_up_pressed():
#	var cost = 5
#	if map_ref.coins < cost:
#		return
#	map_ref.add_coins(-cost)
#	add_worth(cost)
#	update_range(aggro_range + 20.0)
#
#func _on_up2_pressed():
#	var cost = 20
#	if map_ref.coins < cost:
#		return
#	map_ref.add_coins(-cost)
#	add_worth(cost)
#	damage += 10

func on_action_canceled(popup: CatDialog) -> void:
	if popup.visible:
		return
	popup.queue_free()
	call_deferred("try_reselect")

func try_reselect() -> void:
	if state == State.DELETED: return
	await get_tree().create_timer(0.1).timeout
#	print('trying to reselect when selected is %s' % map_ref.cat_selected)
	if !map_ref.cat_selected:
		emit_signal("cat_select")

func on_map_coins_changed(coins: float) -> void:
	el_up1_button.set_state_from_coins(coins)
	el_up2_button.set_state_from_coins(coins)
