extends Node2D

@onready var world = preload("res://World.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_play_pressed():
	var instance = world.instantiate()
	get_tree().current_scene.get_child(0).queue_free()
	get_tree().current_scene.add_child(instance)
	pass # Replace with function body.
