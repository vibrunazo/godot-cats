extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var aggro_list = []
var target: Mouse


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _physics_process(delta):
	if (target):
		follow_target()
		
func follow_target():
	var pos = target.position
#	print('looking at %s at %s' % [target, pos])
	$Turret.look_at(pos)

func acquire_new_target(new_target: Node):
	target = new_target
	if $Cooldown.time_left > 0:
		return
	shoot()
	$Cooldown.start()

func shoot():
	if !target:
		$Cooldown.stop()
		return
	print('shooting at target')

func _on_AggroRange_area_entered(area: Node):
	if !area.get_parent().is_in_group("mice"):
		return
	print('entered range %s' % area.get_parent().is_in_group("mice"))
	acquire_new_target(area.get_parent())


func _on_AggroRange_area_exited(area: Node):
	if !area.get_parent().is_in_group("mice"):
		return
	print('exited range')
	if area.get_parent() == target:
		target = null


func _on_Cooldown_timeout():
	shoot()
