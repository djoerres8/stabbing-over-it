extends RigidBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Skeleton3D/SkeletonIK3D.start()



#const SPEED = 5.0 #movement
const ROTATION_SPEED = 2.0 # Adjust rotation speed as needed

const JUMP_ACCELERATION = 10
const JUMP_MAX = 10
var jump_velocity = 0
var is_space_held = true

const MAX_SPEED = 8
const ACCELERATION = 5

var selected : bool = false
var velocity : Vector3
var speed : Vector3
var start_position : Vector3
var end_position : Vector3


func _physics_process(delta: float) -> void:	
	#Make camera controller match position of self
	$Camera_Controller.position = lerp($Camera_Controller.position, position, .05)

#if event is InputEventMouseMotion:
		#mouse = event.position
	#if event is InputEventMouseButton:
		#if event.pressed == false and event.button_index == MOUSE_BUTTON_LEFT:
			#get_mouse_world_pos(mouse)
		#elif event.pressed == false and event.button_index == MOUSE_BUTTON_RIGHT:
			#grabbed_object = null

func _on_Area_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	pass
		
#func _input(event: InputEvent) -> void:
	#print("event2")
	#if event.is_action_released("click") and event.button_index == MOUSE_BUTTON_LEFT:
		#print("left MB released")
		#if selected:
			##calculate the speed
			#speed = - (direction * distance * ACCELERATION).limit_length(MAX_SPEED)
			#
			#shoot(speed)
			#print("shoot")
		#selected = false
		
		
func shoot(vector:Vector3)->void:
	velocity = Vector3(vector.x, vector.y, 0)
	
	self.apply_impulse(velocity)
		
		
		


func _on_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	
	#isten for mouse buttons
	if event is InputEventMouseButton:
		
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			selected = true
			start_position = event_position # Store the mouse start position
			print("Mouse pressed at position:", start_position)
			
		elif event.is_released() and event.button_index == MOUSE_BUTTON_LEFT and selected:
			end_position = event_position # Store the mouse release position
			print("Mouse released at position:", end_position)
				
			# Calculate direction and distance
			var direction = (end_position - start_position).normalized()
			var distance = (end_position - start_position).length()

			# Calculate speed
			var speed = direction * distance * ACCELERATION
			speed = speed.limit_length(MAX_SPEED)

			# Shoot
			shoot(speed)
			print("Shoot with speed:", speed)
			selected = false
			
			
			
