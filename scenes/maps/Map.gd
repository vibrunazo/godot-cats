extends Node2D

class_name Map

class WaveData:
	var start: float
	var spaws: int
	var cooldown: float

var el_path: Path2D
onready var el_coins: Label = get_node("%CoinLabel")
onready var el_cheese: Label = get_node("%CheeseLabel")
onready var el_pause: PauseMenu = get_node("%PauseMenu")
onready var el_game_over: PauseMenu = get_node("%GameOverMenu")
onready var el_win: PauseMenu = get_node("%WinMenu")
onready var el_time: Label = get_node("%TimeLabel")
onready var el_lifebar: ProgressBar = get_node("%LifeBar")
onready var el_mousebar: ProgressBar = get_node("%MouseBar")

var mouse_scene = preload("res://scenes/Mouse.tscn")
var data = GameData.cat_data
onready var action_buttons: Array = get_tree().get_nodes_in_group("action_button")
var tooltips: Array = []
var all_buttons: Array = []
# the cat currently being built and dragged by the mouse
var cat_building: Cat = null
var cat_selected: Cat = null
export var next_map = "Map02"
export var coins = 20
export var life = 20
onready var max_life = life
export var max_cell_x = 10
export var max_cell_y = 5
export(Curve) var size_curve: Curve
#export var final_time := 500.0
#export var final_size := 1600.0
export var wave_list := [
	{
		"start": 1,
		"spawns": 10,
		"cooldown": 4.0,
		"size_min": 50,
		"size_max": 80
	},
	{
		"start": 16,
		"spawns": 8,
		"cooldown": 0.08,
		"size_min": 2,
		"size_max": 2
	},
	{
		"start": 26,
		"spawns": 12,
		"cooldown": 0.05,
		"size_min": 2,
		"size_max": 2
	},
	{
		"start": 38,
		"spawns": 4,
		"cooldown": 5.0,
		"size_min": 180,
		"size_max": 240
	},
	{
		"start": 35,
		"spawns": 18,
		"cooldown": 0.1,
		"size_min": 2,
		"size_max": 2
	}
]
var wave_state_list := [
	{
		"spawned": 0,
		"timer": null
	}
]
var cats_dict = {
#	[0, 0]: "cat1",
#	[1, 2]: "cat2"
}
var spawn_max := 0
var total_worth: float = 0.0
var spawn_count := 0
var kill_count := 0
var kill_worth := 0.0
var stolen_count := 0
var stolen_worth := 0.0
var start_time := 0
var ellapsed := 0
var max_size := 30.0
var paused: bool = false
enum State {READY, OVER}
var state: int = State.READY

# Called when the node enters the scene tree for the first time.
func _ready():
	if Global.DEBUG_WIN:
		Engine.time_scale = 4
	start_time = Time.get_ticks_msec()
	el_path = $Path2D
	for b in action_buttons:
		var button: CircleButton = b
		var cat_data = data[button.name]
		var cost = cat_data.cost
		b.connect("pressed", self, "action_pressed", [b.get_name(), b])
		b.connect("button_up", self, "action_released", [b.get_name(), b])
		button.update_cost(cost)
		button.register_tooltip()
	ini_waves()
	update_coins()
	update_UI_mousebar()
	update_life()
	pause_game(false)
	play_music()

func _physics_process(_delta):
	if cat_building != null:
		cat_building.position = snap_to_grid(get_global_mouse_position())
		if can_build(get_global_mouse_position()):
			cat_building.modulate = Color.yellow#("ff55ff99")
		else:
			cat_building.modulate = Color.red#("bbaa2222")

func ini_waves():
#	print('ini waves')
	spawn_max = 0
	var i: int = 0
	for wave in wave_list:
		spawn_max += wave.spawns
		total_worth += wave.spawns * Mouse.calculate_worth(wave.size_max)
		build_wave(wave, i)
		i += 1

func build_wave(wave: Dictionary, i: int):
#	print('building wave %s' % wave)
	
	var t: Timer = Timer.new()
	add_child(t)
	var wave_state = {
		"spawned": 0,
		"timer": t
	}
	if wave_state_list.size() > i:
		wave_state_list[i] = wave_state
	else:
		wave_state_list.append(wave_state)
# warning-ignore:return_value_discarded
	t.connect("timeout", self, "wave_timer_timeout", [i])
	yield(get_tree().create_timer(wave.start, false), "timeout")
	print('starting wave %s' % i)
	wave_timer_timeout(i)
	t.start(wave.cooldown)
	
func wave_timer_timeout(i):
	var wave = wave_list[i]
	var wave_state = wave_state_list[i]
	spawn_new_mouse(wave.size_min, wave.size_max)
	wave_state.spawned += 1
	var spawns_left = wave.spawns - wave_state.spawned
	if spawns_left == 0:
		var t: Timer = wave_state.timer
		t.stop()
		t.queue_free()
	if Global.DEBUG_WAVES:
		print('%s: wave %s spawned %s/%s' % [ellapsed, i, wave_state.spawned, wave.spawns])

func play_music():
	yield(get_tree().create_timer(0.4), "timeout")
	$AudioMusic.play()
	
func register_new_button(button: CircleButton):
	all_buttons.append(button)
	var _e 
	_e = button.connect("mouse_entered", self, "button_entered", [button])
	_e = button.connect("mouse_exited", self, "button_exited", [button])
	_e = button.connect("button_up", self, "hide_tooltip_on", [button])
	
func register_new_tooltip(tip: Tooltip):
	tooltips.append(tip)
	var pos := tip.get_global_transform().origin
	tip.get_parent().remove_child(tip)
	$UI/Tooltips.add_child(tip)
	tip.set_global_position(pos)

func button_entered(button: CircleButton):
	show_tooltip_on(button)

func button_exited(button: CircleButton):
	button.hide_tooltip()

# can be either a CircleButton or a Cat
func show_tooltip_on(button):
	for t in tooltips:
		t.hide()
	button.show_tooltip()

# can eb either a CircleButton or a Cat
func hide_tooltip_on(button):
	button.hide_tooltip()

func action_pressed(name: String, _button: CircleButton):
	if cat_building:
		return
	if coins < GameData.cat_data[name]['cost']:
		return
	cat_building = GameData.get_cat_scene(name).instance()
	cat_building.init(self)
	$UI.add_child(cat_building)
#	if !OS.has_touchscreen_ui_hint(): 
#		print('no touch')
#		return
#	show_tooltip_on(button)
	

func action_released(name: String, _button: CircleButton):
	if cat_building:
		if can_build(cat_building.global_position):
			build_cat(name)
		else:
			cancel_build()
		
func build_cat(name):
	cat_building.position = snap_to_grid(cat_building.global_position)
	var cell_pos = $TileMap.world_to_map(cat_building.global_position)
	if cats_dict.get([int(cell_pos.x), int(cell_pos.y)]):
		print("already a cat at %s is %s" % [cell_pos, cats_dict.get(cell_pos)])
		return
	else:
#		print("building cat at %s" % cell_pos)
		cats_dict[cell_pos] = cat_building
	
	$UI.remove_child(cat_building)
	$Actors.add_child(cat_building)
# warning-ignore:return_value_discarded
	cat_building.connect("clicked", self, "_on_cat_clicked", [cat_building])
	cat_building.done_building(cell_pos)
	cat_building = null
	add_coins(-data[name]['cost'])
	
func cancel_build():
	cat_building.queue_free()
	cat_building = null
	
func remove_cat_at_cell(cell_pos: Vector2):
	cats_dict[cell_pos] = null
	
#func is_paused() -> bool:
#	return get_tree().paused

func toggle_pause():
	if state != State.READY: return
	el_pause.toogle()
#	pause_game(!paused)

func pause_game(new_paused: bool):
	paused = new_paused
	el_pause.visible = paused
#	print("paused: %s" % paused)
#	get_tree().paused = new_paused
	el_pause.pause(paused)

func update_UI_time():
	el_time.text = str(ellapsed)#.pad_zeros(3)
#	el_mousebar.value = clamp(ellapsed, 0, 100)

func update_UI_mousebar():
	# kills needed to win, after killing this many, you can't lose anymore
#	var kills_needed = spawn_max - max_life + 1
	var kills_needed = total_worth - max_life + 1
	# how many mice left to kill to get to the kills needed to win
	var worth_left = max(kills_needed - kill_worth, 0)
	var value = 0
	if kills_needed > 0:
		value = ceil(100 * worth_left / kills_needed)
	el_mousebar.value = clamp(value, 0, 100)
#	if mouse_left == 0:
#		print('cannot lose anymore')
	var stolen = max_life - life
#	print("kill worth %s + stolen %s >= total worth %s (%s) and life %s, worth left: %s, worth needed: %s, value: %s" % [kill_worth, stolen, total_worth, (kill_worth + stolen >= total_worth),life, worth_left, kills_needed, value])
	# round() is to workaround float precision
	if round(kill_worth) + round(stolen) >= round(total_worth) and life > 0:
		win()

func win():
	print('you win')
	yield(get_tree().create_timer(2),"timeout")
	if life == max_life:
		print("Puurfect!")
	state = State.OVER
	el_win.slow_pause()
	
func add_life(ammount):
	life += ammount
	life = max(0, life)
	update_life()
	
func update_life():
	el_cheese.text = "%s" % life
	el_lifebar.value = life * 100 / max_life
	if life == 0:
		game_over()
	
func game_over():
	state = State.OVER
#	audio_fade_out()
#	yield($TweenAudio,"tween_completed")
	el_game_over.slow_pause()

func add_coins(ammount):
	coins += ammount
	update_coins()

func update_coins():
	el_coins.text = "$%s" % floor(coins)
	for b in action_buttons:
		var button: CircleButton = b
		button.set_state_from_coins(coins)
	if is_instance_valid(cat_selected):
		cat_selected.on_map_coins_changed(coins)
	
func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()
#	print('new event %s' % event)
		
		
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

func spawn_new_mouse(s1 = 30, s2 = 60):
	if (spawn_count >= spawn_max): 
		$SpawnTimer.stop()
		return
	spawn_count += 1
	var mouse: Mouse = mouse_scene.instance()
	mouse.position = Vector2(0, 0)
	
	var min_size = s1
#	max_size = min_size + pow(ellapsed, 2.0) * 0.0100
#	var interp = size_curve.interpolate(ellapsed / final_time)
#	max_size = min_size + interp * (final_size - min_size)
#	print('ellpased: %s, interp: %s, maxsize: %s' % [ellapsed, interp, max_size])
	if Global.DEBUG_WIN:
		max_size = 40
	max_size = s2
	var h = rand_range(min_size, max_size)
	# makes it exponential distribution, so big sizes are more rare, 
	# while keeping same min and max sizes
	h = min_size + pow(h, 4) * (min_size + max_size) / pow(max_size + min_size, 4)
	mouse.max_health = h
	
	var min_speed = 35
	var max_speed = min(110, min_speed + ellapsed * 0.155)
	var s = rand_range(min_speed, max_speed)
	s = min_speed + pow(s, 3) * (min_speed + max_speed) / pow(min_speed + max_speed, 3)
	mouse.speed = s
	mouse.update_worth(s2)
	el_path.add_child(mouse)
# warning-ignore:return_value_discarded
	mouse.connect("killed", self, "_on_mouse_killed", [mouse])
# warning-ignore:return_value_discarded
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
	var worth = mouse.worth
	kill_count += 1
	kill_worth += mouse.worth
	add_coins(worth)
	update_UI_mousebar()

func _on_mouse_reached_cheese(mouse: Mouse):
#	kill_count += 1
	stolen_count += 1
	add_life(-mouse.worth)
	update_UI_mousebar()

func _on_cat_clicked(cat: Cat):
	print('clicked cat %s' % cat.name)
	if cat == cat_selected:
		cat_selected = null
		cat.unselect()
		hide_tooltip_on(cat)
	else:
		if is_instance_valid(cat_selected):
			cat_selected.unselect()
		cat.select()
		cat_selected = cat
		show_tooltip_on(cat)

func _on_SettingsButton_pressed():
	toggle_pause()

func _on_EllapsedTimer_timeout():
	if Global.DEBUG_WIN:
		Engine.time_scale = 4
	elif Engine.time_scale > 1:
		Engine.time_scale = 1
	if kill_count + stolen_count >= spawn_max:
		$EllapsedTimer.stop()
		return
	ellapsed += 1
	update_UI_time()


func _on_NextButton_pressed():
	pause_game(false)
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://scenes/maps/%s.tscn" % next_map)
