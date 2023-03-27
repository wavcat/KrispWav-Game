extends Node

@onready var player = $Player
@onready var farm = $"Farming System"
@onready var CropDatabase = farm.CropDatabase
var Cur_day
var quit = "quit"


func _input(event):
	if event.is_action_pressed("quit"):
		get_tree().quit()
		
		
	if Input.is_action_just_pressed("leftMouseButton"):
		var pointPOS = player.get_global_mouse_position()
		var pointerTile = farm.local_to_map(pointPOS)
		if farm.get_cell_atlas_coords(0, pointerTile) != Vector2i(3,8):
			tilledDirt(pointerTile)
		else:
			if farm.get_cell_atlas_coords(1, pointerTile) != Vector2i(2,8):
				wateredDirt(pointerTile)

func tilledDirt(pointerTile):
		print(farm.get_cell_tile_data(0,pointerTile))
		farm.set_cell(0, pointerTile, 0, Vector2(3,8), 0)
		print(pointerTile)
		
		
		
func wateredDirt(pointerTile):
		print(farm.get_cell_tile_data(0,pointerTile))
		farm.set_cell(1, pointerTile, 0, Vector2(2,8), 0)
		print(pointerTile)
