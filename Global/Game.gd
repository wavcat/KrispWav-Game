extends Node

var Cur_day
var quit = "quit"

func _input(event):
	if event.is_action_pressed("quit"):
		get_tree().quit()
