extends Node

# script for settings configurations
# all options that can be changed in the in-game settings menu 
# and saved in the config file will be stored here

# whether clicking actions should show a confirm dialog first
# if true shows a confirm dialog before applying the action
# if false applies the action as soon as the button is clicked
var confirm: bool = true


# Called when the node enters the scene tree for the first time.
func _ready():
	print('config ready')

