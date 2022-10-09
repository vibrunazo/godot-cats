extends Node

class_name Action

export var action_name: String = 'action_range'
export var description: String = 'action_range_desc' setget , get_desc
export var method: String = ''
export var binds: Array = []
export var cost: float = 10
export var icon: Texture
export var icon_size: Vector2 = Vector2(64, 64)
export var icon_tint: Color = Color.white

func get_desc():
	var dic = {}
	var i = 0
	for b in binds:
		dic[i] = '[color=#ee1]%s[/color]' % b
		i += 1
	return tr(description).format(dic)
