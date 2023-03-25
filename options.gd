extends Node2D


func _on_button_2_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _on_button_pressed():
	print("No Audio Yet, Loser")

func _on_button_5_pressed():
	get_tree().change_scene_to_file("res://controls.tscn")
