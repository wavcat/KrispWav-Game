extends Resource

class_name SlotData

const MAX_STACK_SIZE: int = 999

@export var item_data: ItemData
@export_range(1,MAX_STACK_SIZE) var quantity: int = 1: set = set_quantity

#Checks if the item you are trying to drop is able to be merged with the item you clicked.
func can_merge_with(other_slot_data: SlotData) -> bool:
	return item_data == other_slot_data.item_data \
	and item_data.Stackable \
	and quantity < MAX_STACK_SIZE


#Confirms that the item quantity after merging will still be under the max stack limit.
func can_fully_merge_with(other_slot_data: SlotData) -> bool:
	return item_data == other_slot_data.item_data \
	and item_data.Stackable \
	and quantity + other_slot_data.quantity < MAX_STACK_SIZE


#Merges slots together.
func fully_merge_with(other_slot_data: SlotData):
	quantity += other_slot_data.quantity

#Removes a single item from the stack and creates a new stack containing just a single item.
func create_single_slot_data() -> SlotData:
	var new_slot_data = duplicate()
	new_slot_data.quantity = 1
	quantity -= 1
	return new_slot_data


#Assigns the item's quantity.
func set_quantity(value: int):
	quantity = value
	if quantity > 1 and not item_data.Stackable:
		quantity = 1
		push_error("%s is not stackable, setting quantity to 1" % item_data.Name)
