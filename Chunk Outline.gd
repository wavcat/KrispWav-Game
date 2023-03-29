extends Node2D

var chunk 
# Called when the node enters the scene tree for the first time.
func _ready():
	$Label.text = str(chunk)
	self.global_position = Vector2(chunk.x*160,chunk.y*160)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

