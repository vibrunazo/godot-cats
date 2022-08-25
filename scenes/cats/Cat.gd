extends Node2D

class_name Cat, "res://assets/cat01.png"
signal clicked


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var aggro_list = []
var target: Mouse
var bullet_scene = preload("res://scenes/Bullet.tscn")
onready var spawn_position: Position2D = $Turret/SpawnPosition
onready var bullet_sprite: Sprite = $Turret/SpawnPosition/BulletSprite
export var building = true
export var SELECTION_SIZE := 400
export var selected = true
export var damage = 10
export var shot_speed = 400


# Called when the node enters the scene tree for the first time.
func _ready():
	if selected:
		var selection_scale = ($AggroRange/AggroShape.shape.radius * 2) / SELECTION_SIZE
		$SelectionCircle.scale = Vector2(selection_scale, selection_scale)
		$SelectionCircle.visible = true
	else:
		$SelectionCircle.visible = false
	if !building:
		done_building()
	
func done_building():
	building = false
	$AggroRange.monitoring = true
	unselect()
	$AnimationPlayer.play("idle")
	modulate = Color.white
	
func select():
	selected = true
	$SelectionCircle.visible = true
	update_aggro_labels()
	
func unselect():
	selected = false
	$SelectionCircle.visible = false
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
	var best_score := 0
	var best: Mouse = aggro_list[0]
	for m in aggro_list:
		var mouse: Mouse = m
		if mouse.offset > best_score:
			best_score = mouse.offset
			best = mouse
#	print('best is %s' % best)
	acquire_new_target(best)

func shoot():
	if !target:
		$Cooldown.stop()
		return
	var bullet = bullet_scene.instance()
	bullet.position = spawn_position.global_position
	bullet.damage = damage
	bullet.speed = shot_speed
	bullet.set_target(target)
	get_tree().root.add_child(bullet)
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
