extends Control

signal drop_slot_data(slot_data: SlotData)

var grabbed_slot_data: SlotData
var external_inventory_owner

@onready var player_inventory = $PlayerInventory
@onready var grabbed_slot = $GrabbedSlot
@onready var external_inventory = $ExternalInventory

func _physics_process(delta):
	if grabbed_slot.visible:
		grabbed_slot.global_position = get_global_mouse_position() + Vector2(1,1)


#Loads the player's inventory data into the PlayerInventory Slot. Called on loadup.
func set_player_inventory(inventory_data: InventoryData):
	inventory_data.inventory_interact.connect(on_inventory_interact)
	player_inventory.set_inventory(inventory_data)


#Loads the External Inventory of a chest, only called when a chest is interacted with.
func set_external_inventory(_external_inventory_owner):
	external_inventory_owner = _external_inventory_owner
	var inventory_data = external_inventory_owner.inventory_data
	
	inventory_data.inventory_interact.connect(on_inventory_interact)
	external_inventory.set_inventory(inventory_data)
	
	external_inventory.show()


#Clears the data from the External Inventory node, called when you stop interacting with a chest.
func clear_external_inventory():
	if external_inventory_owner:
		var inventory_data = external_inventory_owner.inventory_data
		
		inventory_data.inventory_interact.disconnect(on_inventory_interact)
		external_inventory.clear_inventory(inventory_data)
		
		external_inventory.hide()
		external_inventory_owner = null


#Controls what interaction options you have with an inventory slot.
func on_inventory_interact(inventory_data: InventoryData, index: int, button: int):
#	print("%s %s %s" % [inventory, index, button])
	match [grabbed_slot_data, button]:
		[null, MOUSE_BUTTON_LEFT]: #If you aren't holding an item and you left click an item, grab that item data.
			grabbed_slot_data = inventory_data.grab_slot_data(index)
		[_, MOUSE_BUTTON_LEFT]: #If you are holding an item, and you left click a slot, drop that item stack and/or grab the item of the new slot.
			grabbed_slot_data = inventory_data.drop_slot_data(grabbed_slot_data,index)
		[null, MOUSE_BUTTON_RIGHT]:
			inventory_data.use_slot_data(index)
		[_, MOUSE_BUTTON_RIGHT]: #If you are holding an item and you right click a slot, drop a single item from the stack and keep the rest of the stack grabbed.
			grabbed_slot_data = inventory_data.drop_single_slot_data(grabbed_slot_data,index)
	
	update_grabbed_slot()

#Updates the GrabbedSlot Node with the item data. Called whenever you grab or drop an item.
func update_grabbed_slot():
	if grabbed_slot_data:
		grabbed_slot.show()
		grabbed_slot.set_slot_data(grabbed_slot_data)
	else:
		grabbed_slot.hide()

#Controls what options you have when you are holding an item and you don't click an inventory slot.
func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.is_pressed() and grabbed_slot_data:
		match event.button_index:
			MOUSE_BUTTON_LEFT: #If you are holding an item and you left click somewhere outside of your inventory, you drop the entire item stack.
				drop_slot_data.emit(grabbed_slot_data)
				grabbed_slot_data = null
			MOUSE_BUTTON_RIGHT: #If you are holding an item and you right click somewhere outside of your inventory, you drop a single item from the stack.
				drop_slot_data.emit(grabbed_slot_data.create_single_slot_data())
				if grabbed_slot_data.quantity < 1:
					grabbed_slot_data = null
				
		update_grabbed_slot()


func _on_visibility_changed(): #If you are holding an item and you close out of the inventory, automatically drop the entire item stack you were holding.
	if not visible and grabbed_slot_data:
		drop_slot_data.emit(grabbed_slot_data)
		grabbed_slot_data = null
		update_grabbed_slot()
