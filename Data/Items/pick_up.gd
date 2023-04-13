extends RigidBody2D

@export var slot_data: SlotData

@onready var sprite_2d = $Sprite2D

func _ready():
	sprite_2d.texture = slot_data.item_data.Icon


func _on_area_2d_body_entered(body):
	if body.player_inventory.pick_up_slot_data(slot_data):
		self.queue_free()
	pass # Replace with function body.
