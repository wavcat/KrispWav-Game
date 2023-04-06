extends StaticBody2D

signal toggle_inventory(external_inventory_owner)

@export var inventory_data: InventoryData


func player_interact():
	toggle_inventory.emit(self)
