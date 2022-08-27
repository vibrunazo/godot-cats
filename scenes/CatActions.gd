extends Control

class_name CatActions

signal up_pressed
signal up2_pressed
signal delete_pressed

func _ready():
	pass # Replace with function body.

func _on_UpButton_pressed():
	emit_signal("up_pressed")

func _on_Up2Button_pressed():
	emit_signal("up2_pressed")

func _on_DeleteButton_pressed():
	emit_signal("delete_pressed")
