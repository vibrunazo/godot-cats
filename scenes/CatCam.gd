extends Camera2D

class_name CatCam

var shake_amount = 1.0
var shaking = false
var timers: Array = []

func _process(_delta):
	if !shaking: return
	set_offset(Vector2( \
		rand_range(-1.0, 1.0) * shake_amount, \
		rand_range(-1.0, 1.0) * shake_amount \
	))

func shake(amplitude: float = 5.0, duration: float = 0.12):
	shaking = true
	shake_amount = amplitude
	
	var t: Timer = Timer.new()
	add_child(t)
	timers.append(t)
	# warning-ignore:return_value_discarded
	t.connect("timeout", self, "shake_timer_timeout", [t])
	t.start(duration)

func shake_timer_timeout(timer: Timer):
	set_offset(Vector2(0, 0))
	var i = timers.find(timer)
	timers.remove(i)
	timer.stop()
	timer.queue_free()
	if timers.size() == 0:
		shaking = false
