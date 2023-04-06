extends CharacterBody2D

signal toggle_inventory
@export var move_speed : float = 100
@export var starting_direction : Vector2 = Vector2(0, 1)
@onready var ray:=$Arrow/RayCast2D
@onready var pointer:= $Arrow

@export var player_inventory: InventoryData

# parameters/Idle/blend_position

#@onready var animation_tree = $AnimationTree
#@onready var state_machine = animation_tree.get("parameters/playback")

func rotate_pointer(point_direction:Vector2)->void:
	var temp = rad_to_deg(atan2(point_direction.y, point_direction.x))
	pointer.rotation_degrees = temp

func _unhandled_input(event: InputEvent):
	if Input.is_action_just_pressed("ui_focus_next"):
		toggle_inventory.emit()
	


func _ready():
	update_animation_parameters(starting_direction)

func _physics_process(_delta):

	var input_direction = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	
	update_animation_parameters(input_direction)
	
	velocity = input_direction * move_speed

	move_and_slide()
	if velocity != Vector2.ZERO:
		rotate_pointer(velocity)
	
	#if $Arrow/RayCast2D.is_colliding():
		#this is for knowing if you are colliding with something, just a test because ⬇️
	
	
	
func update_animation_parameters(move_input : Vector2):
	if(move_input != Vector2.ZERO):
		$AnimationTree.set("parameters/Walk/blend_position", move_input)
		$AnimationTree.set("parameters/Idle/blend_position", move_input)

func pick_new_state():
	if(velocity != Vector2.ZERO):
		$AnimationPlayer.travel("Walk")
	else:
		$AnimationPlayer.travel("Idle")
