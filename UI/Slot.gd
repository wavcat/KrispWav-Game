extends PanelContainer

signal slot_clicked(index: int, button: int)

@onready var texture_rect = $MarginContainer/TextureRect
@onready var quantity = $Quantity

var self_index

func _ready():
	self_index = get_parent().get_child_count()-1
#Loads the slots item data and quantity. Only called when item data is placed into a slot.
func set_slot_data(slot_data: SlotData) -> void:
	var item_data = slot_data.item_data
	texture_rect.texture = item_data.Icon
	tooltip_text = "%s \n%s" % [item_data.Name, item_data.Description]
	if slot_data.quantity > 1:
		quantity.text = str(slot_data.quantity)
		quantity.show()
	else:
		quantity.hide()


#Sends a signal containing the slot information when it is clicked, used for grabbing and dropping item data.
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT) and event.is_pressed():
		slot_clicked.emit(get_index(), event.button_index)

#		if texture_rect.get_material():
#			texture_rect.material = null 
#		else:
#			texture_rect.get_material().set_shader_parameter("line_thickness",0.5)

	pass # Replace with function body.
