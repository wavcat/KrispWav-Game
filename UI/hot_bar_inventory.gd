extends PanelContainer

signal hot_bar_use(index: int)

@onready var h_box_container = $MarginContainer/HBoxContainer

const Slot = preload("res://UI/Slot.tscn")


func _unhandled_input(event: InputEvent):
	if not visible or not event.is_pressed():
		return
	
	#This code below uses an item from the hotbar that lines up with the numbers on keyboard
	#This will be changed later on to use the scroll wheel to decide what slot to use.
	if range(KEY_1, KEY_9).has(event.keycode):
		hot_bar_use.emit(event.keycode - KEY_1)
		print (event.keycode - KEY_1)


func set_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_updated.connect(populate_hot_bar)
	populate_hot_bar(inventory_data)
	hot_bar_use.connect(inventory_data.use_slot_data)


func populate_hot_bar(inventory_data: InventoryData) -> void:
	for child in h_box_container.get_children():
		child.queue_free()
	
	for slot_data in inventory_data.slot_datas.slice(0,10):
		var new_slot = Slot.instantiate()
		h_box_container.add_child(new_slot)

		if slot_data:
			new_slot.set_slot_data(slot_data)
	pass
	
