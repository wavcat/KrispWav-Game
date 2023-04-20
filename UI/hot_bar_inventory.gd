extends PanelContainer

signal hot_bar_use(index: int)

@onready var h_box_container = $MarginContainer/HBoxContainer

const Slot = preload("res://UI/Slot.tscn")
const shader = preload("res://Scripts/Shaders/Outline.gdshader")

var current_slot:int = 0



func _input(event: InputEvent):
	if not visible or not event.is_pressed():
		return
	
	if event is InputEventMouseButton:
#Right clicking when not in an inventory will attempt to use the item in the active slot, scroll wheel cycles through the different slots.
		if event.button_index == MOUSE_BUTTON_RIGHT:
			hot_bar_use.emit(current_slot)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_slot -= 1
			if current_slot < 0:
				current_slot = 9
			slot_active(current_slot)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_slot += 1
			if current_slot > 9:
				current_slot = 0
			slot_active(current_slot)



func set_inventory(inventory_data: InventoryData) -> void:
	inventory_data.inventory_updated.connect(populate_hot_bar)
	populate_hot_bar(inventory_data)
	hot_bar_use.connect(inventory_data.use_slot_data)
	


func populate_hot_bar(inventory_data: InventoryData) -> void:
	for child in h_box_container.get_children():
		child.queue_free()
	
	for slot_data in inventory_data.slot_datas:
		var new_slot = Slot.instantiate()
		h_box_container.add_child(new_slot)
		
		new_slot.slot_clicked.connect(inventory_data.on_slot_clicked)
		
		if slot_data:
			new_slot.set_slot_data(slot_data)
	slot_active(current_slot)
	pass

func slot_active(index):
	print (h_box_container.get_child_count())
	if h_box_container.get_child_count() == 10:
		for child in h_box_container.get_children():
			child.material = null
		if h_box_container.get_child(current_slot):
			var child = h_box_container.get_child(current_slot)
			child.material = ShaderMaterial.new()
			child.material.shader = shader
	if h_box_container.get_child_count() == 11:
		for child in h_box_container.get_children():
			child.material = null
		if h_box_container.get_child(current_slot+1):
			var child = h_box_container.get_child(current_slot+1)
			child.material = ShaderMaterial.new()
			child.material.shader = shader



func _on_h_box_container_child_entered_tree(node):
	slot_active(current_slot)
	pass # Replace with function body.


func _on_h_box_container_child_exiting_tree(node):
	slot_active(current_slot)
	pass # Replace with function body.
