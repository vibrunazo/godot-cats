extends Camera2D

class_name CatCam

var shake_amount: float = 1.0
var shaking: bool = false
var timers: Array[Timer] = []

func _process(_delta: float) -> void:
	if !shaking: return
	offset = Vector2(
		randf_range(-1.0, 1.0) * shake_amount,
		randf_range(-1.0, 1.0) * shake_amount
	)

func shake(amplitude: float = 5.0, duration: float = 0.12) -> void:
	shaking = true
	shake_amount = amplitude
	
	var t: Timer = Timer.new()
	add_child(t)
	timers.append(t)
	# warning-ignore:return_value_discarded
	t.connect("timeout", Callable(self, "shake_timer_timeout").bind(t))
	t.start(duration)

func shake_timer_timeout(timer: Timer) -> void:
	set_offset(Vector2(0, 0))
	var i: int = timers.find(timer)
	timers.remove_at(i)
	timer.stop()
	timer.queue_free()
	if timers.size() == 0:
		shaking = false
