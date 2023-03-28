extends Node2D

@onready var menu = load("res://main_menu.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	var instance = menu.instantiate()
	add_child(instance)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
