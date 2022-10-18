extends Camera2D

class_name CatCam

var shake_amount = 1.0
var shaking = false

func _process(_delta):
	if !shaking: return
	set_offset(Vector2( \
		rand_range(-1.0, 1.0) * shake_amount, \
		rand_range(-1.0, 1.0) * shake_amount \
	))

func shake(amplitude: float = 5.0, duration: float = 0.12):
	shaking = true
	shake_amount = amplitude
	yield(get_tree().create_timer(duration), "timeout")
	shaking = false
	set_offset(Vector2(0, 0))
