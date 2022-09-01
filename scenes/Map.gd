extends Node2D

class_name Map

var el_path: Path2D
onready var el_coins: Label = get_node("%CoinLabel")
onready var el_cheese: Label = get_node("%CheeseLabel")
onready var el_pause: PauseMenu = get_node("%PauseMenu")

var mouse_scene = preload("res://scenes/Mouse.tscn")
var data = GameData.cat_data

# the cat currently being built and dragged by the mouse
var cat_building: Cat = null
var cat_selected: Cat = null
export var coins = 20
export var life = 20
export var max_cell_x = 10
export var max_cell_y = 5
var cats_dict = {
#	[0, 0]: "cat1",
#	[1, 2]: "cat2"
}

var spawn_count := 0
var start_time := 0
var ellapsed := 0
var max_size := 30.0
var paused: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
#	Engine.time_scale = 2
	start_time = Time.get_ticks_msec()
	el_path = $Path2D
	for b in get_tree().get_nodes_in_group("action_button"):
		var button: CircleButton = b
		var cat_data = data[button.name]
		var cost = cat_data.cost
		print("found action button %s" % b.get_name())
		b.connect("pressed", self, "action_pressed", [b.get_name()])
		b.connect("button_up", self, "action_released", [b.get_name()])
		button.update_cost(cost)
	update_coins()
		
func action_pressed(name):
	print("pressed action %s" % name)
	if cat_building:
		return
	if coins < GameData.cat_data[name]['cost']:
		return
	cat_building = GameData.get_cat_scene(name).instance()
	cat_building.init(self)
	$UI.add_child(cat_building)

func action_released(name):
	print('action released')
	if cat_building:
		if can_build(get_global_mouse_position()):
			build_cat(name)
		else:
			cancel_build()
		
func build_cat(name):
	var cell_pos = $TileMap.world_to_map(cat_building.global_position)
	if cats_dict.get([int(cell_pos.x), int(cell_pos.y)]):
		print("already a cat at %s is %s" % [cell_pos, cats_dict.get(cell_pos)])
		return
	else:
#		print("building cat at %s" % cell_pos)
		cats_dict[cell_pos] = cat_building
	
	$UI.remove_child(cat_building)
	$Cats.add_child(cat_building)
	cat_building.connect("clicked", self, "_on_cat_clicked", [cat_building])
	cat_building.done_building(cell_pos)
	cat_building = null
	add_coins(-data[name]['cost'])
	
func cancel_build():
	cat_building.queue_free()
	cat_building = null
	
func remove_cat_at_cell(cell_pos: Vector2):
	cats_dict[cell_pos] = null

func toggle_pause():
	el_pause.toogle()
#	pause_game(!paused)

func pause_game(new_paused: bool):
	paused = new_paused
	el_pause.visible = paused
#	print("paused: %s" % paused)
#	get_tree().paused = new_paused
	el_pause.pause(paused)

func add_life(ammount):
	life += ammount
	life = max(0, life)
	update_life()
	
func update_life():
	el_cheese.text = "%s" % life

func add_coins(ammount):
	coins += ammount
	update_coins()

func update_coins():
	el_coins.text = "$%s" % coins
	for b in get_tree().get_nodes_in_group("action_button"):
		var button: CircleButton = b
		button.set_state_from_coins(coins)
	if is_instance_valid(cat_selected):
		cat_selected.on_map_coins_changed(coins)
	
#func _unhandled_input(event):
#	print('new event %s' % event)

func _physics_process(delta):
	if cat_building != null:
		cat_building.position = snap_to_grid(get_global_mouse_position())
		if can_build(get_global_mouse_position()):
			cat_building.modulate = Color.yellow#("ff55ff99")
		else:
			cat_building.modulate = Color.red#("bbaa2222")
		
func snap_to_grid(position: Vector2):
	var map_position = $TileMap.world_to_map(position)
	var cell_position = $TileMap.map_to_world(map_position)
	var pos_x = (cell_position.x + 64)
	var pos_y = (cell_position.y + 64)
	return Vector2(pos_x, pos_y)

func can_build(position: Vector2) -> bool:
	var cell_pos = $TileMap.world_to_map(position)
	var id = $TileRoad.get_cellv(cell_pos)
	
	if id == 0 : return false
	if cats_dict.get(cell_pos): return false
	if !is_inside_map(cell_pos): return false
	return true

func is_inside_map(cell_pos: Vector2):
	var x1 = 0
	var y1 = 0
	var x2 = max_cell_x
	var y2 = max_cell_y
	if cell_pos.x < x1 or cell_pos.x > x2: return false
	if cell_pos.y < y1 or cell_pos.y > y2: return false
	return true

func spawn_new_mouse():
	spawn_count += 1
	var mouse = mouse_scene.instance()
	mouse.position = Vector2(0, 0)
	ellapsed = (Time.get_ticks_msec() - start_time) / 1000
	
	var min_size = 30
	max_size = min_size + pow(ellapsed, 1.5) * 0.1
	var h = rand_range(min_size, max_size)
	# makes it exponential distribution, so big sizes are more rare, 
	# while keeping same min and max sizes
	h = min_size + pow(h, 4) * (min_size + max_size) / pow(max_size + min_size, 4)
	mouse.max_health = h
	
	var min_speed = 35
	var max_speed = min(110, min_speed + ellapsed * 0.145)
	var s = rand_range(min_speed, max_speed)
	s = min_speed + pow(s, 3) * (min_speed + max_speed) / pow(min_speed + max_speed, 3)
	mouse.speed = s
	el_path.add_child(mouse)
	mouse.connect("killed", self, "_on_mouse_killed", [mouse])
	mouse.connect("cheese", self, "_on_mouse_reached_cheese", [mouse])

func _on_SpawnTimer_timeout():
	spawn_new_mouse()
	if $SpawnTimer.wait_time >= 3.0:
		$SpawnTimer.wait_time -= 0.2#$SpawnTimer.wait_time * 0.05
	elif $SpawnTimer.wait_time >= 2.0:
		$SpawnTimer.wait_time -= $SpawnTimer.wait_time * 0.01
	elif $SpawnTimer.wait_time >= 1.2:
		$SpawnTimer.wait_time -= $SpawnTimer.wait_time * 0.005
	elif $SpawnTimer.wait_time >= 0.5:
		$SpawnTimer.wait_time -= $SpawnTimer.wait_time * 0.002
	if $SpawnTimer.wait_time >= 0.5 and Global.DEBUG_MAP_TIMER:
		print("new spawn timer is %f" % $SpawnTimer.wait_time)
	
	
func _on_mouse_killed(mouse: Mouse):
	var hp = mouse.max_health
	# 80hp is 2 coins, 253hp is 3 coins, 504 is 4 coins
	var worth = 1 + floor(pow(hp, 0.6) / 13.8)
	add_coins(worth)

func _on_mouse_reached_cheese(mouse: Mouse):
	add_life(-1)

func _on_cat_clicked(cat: Cat):
	print('clicked cat %s' % cat.name)
	if cat == cat_selected:
		cat_selected = null
		cat.unselect()
	else:
		if is_instance_valid(cat_selected):
			cat_selected.unselect()
		cat.select()
		cat_selected = cat
		


func _on_SettingsButton_pressed():
	toggle_pause()
