extends Node2D

class_name Cat, "res://assets/cat01.png"


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var aggro_list = []
var target: Mouse
var bullet_scene = preload("res://scenes/Bullet.tscn")
onready var bullet_sprite: Sprite = $Turret/Sprite/SpawnPosition/BulletSprite
export var building = true


# Called when the node enters the scene tree for the first time.
func _ready():
	if !building:
		done_building()
	
func done_building():
	building = false
	$AggroRange.monitoring = true


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
	target.connect("killed", self, "_on_target_died")
	follow_target()
	if $Cooldown.time_left > 0:
		return
	shoot()
	$Cooldown.start()

func _on_target_died():
#	print('target died')
	aggro_list.erase(target)
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
	bullet.position = $Turret/Sprite/SpawnPosition.global_position
	bullet.set_target(target)
	get_tree().root.add_child(bullet)
	play_bullet_anim()

func play_bullet_anim():
	bullet_sprite.visible = false
	yield(get_tree().create_timer(.4), "timeout")
	bullet_sprite.visible = true

func _on_AggroRange_area_entered(area: Node):
	if !area.get_parent().is_in_group("mice"):
		return
	var mouse: Mouse = area.get_parent()
	aggro_list.append(mouse)
	if !target:
		search_new_target()
#		acquire_new_target(mouse)
#	print(aggro_list)


func _on_AggroRange_area_exited(area: Node):
	if !area.get_parent().is_in_group("mice"):
		return
	var mouse: Mouse = area.get_parent()
	aggro_list.erase(mouse)
	if mouse == target:
		target = null
		search_new_target()
	
#	print(aggro_list)


func _on_Cooldown_timeout():
	shoot()
