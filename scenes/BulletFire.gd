extends Bullet


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	$AnimationPlayer.play("fire", 0, 5.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
