extends Node

class_name Action

@export var action_name: String = 'action_range'
@export var description: String = 'action_range_desc': get = get_desc
@export var method: String = ''
@export var binds: Array = []
@export var cost: int = 10
@export var icon: Texture2D
@export var icon_size: Vector2 = Vector2(64, 64)
@export var icon_tint: Color = Color.WHITE

func get_desc() -> String:
	var dic: Dictionary = {}
	var i: int = 0
	for b: Variant in binds:
		var val: Variant = b
		if b is float and is_equal_approx(b, floor(b)):
			val = int(b)
		dic[i] = '[color=#ee1]%s[/color]' % str(val)
		i += 1
	return tr(description).format(dic)

