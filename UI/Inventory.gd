extends PanelContainer

const Slot = preload("res://UI/Slot.tscn")
@onready var item_grid : GridContainer = $MarginContainer/GridContainer

#Links the inventory to the variable and populates its' slots
func set_inventory(inventory_data: InventoryData) ->void:
	inventory_data.inventory_updated.connect(populate_item_grid)
	populate_item_grid(inventory_data)


#Clears the inventory
func clear_inventory(inventory_data: InventoryData) ->void:
	inventory_data.inventory_updated.disconnect(populate_item_grid)



#Loads the individual items within the inventory as children.
func populate_item_grid(inventory_data: InventoryData) -> void:
	for child in item_grid.get_children():
		child.queue_free()
	
	for slot_data in inventory_data.slot_datas:
		var new_slot = Slot.instantiate()
		item_grid.add_child(new_slot)
		
		new_slot.slot_clicked.connect(inventory_data.on_slot_clicked)

		if slot_data:
			new_slot.set_slot_data(slot_data)
	pass
	
