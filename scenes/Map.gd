extends Node2D


var el_path: Path2D
var mouse_scene = preload("res://scenes/Mouse.tscn")
var cat_scene = preload("res://scenes/Cat.tscn")

# the cat currently being built and dragged by the mouse
var cat_building: Cat = null
export var coins = 20

# Called when the node enters the scene tree for the first time.
func _ready():
	el_path = $Path2D
	for b in get_tree().get_nodes_in_group("action_button"):
		print("found action button %s" % b.get_name())
		b.connect("pressed", self, "action_pressed", [b.get_name()])
		b.connect("button_up", self, "action_released", [b.get_name()])
	update_coins()
		
func action_pressed(name):
	print("pressed action %s" % name)
	if cat_building:
		return
	if coins < 10:
		return
	cat_building = cat_scene.instance()
	$UI.add_child(cat_building)

func action_released(name):
	print('action released')
	if cat_building:
		cat_building.done_building()
		cat_building = null
		add_coins(-10)

func add_coins(ammount):
	coins += ammount
	update_coins()

func update_coins():
	$UI/HUD/ActionBar/CoinLabel.text = "$%s" % coins

#func _unhandled_input(event):
#	print('new event %s' % event)

func _physics_process(delta):
	if cat_building != null:
		cat_building.position = get_global_mouse_position()

func spawn_new_mouse():
	var mouse = mouse_scene.instance()
	mouse.position = Vector2(0, 0)
	el_path.add_child(mouse)
	mouse.connect("killed", self, "_on_mouse_killed", [mouse])

func _on_SpawnTimer_timeout():
	spawn_new_mouse()
	if $SpawnTimer.wait_time >= 1.0:
		$SpawnTimer.wait_time -= 0.1
		print("new spawn timer is %f" % $SpawnTimer.wait_time)
	
func _on_mouse_killed(mouse: Mouse):
	add_coins(1)
	

