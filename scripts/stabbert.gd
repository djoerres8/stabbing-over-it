extends RigidBody3D

#controls the bending of the sword when dragging
@onready var handle: Node3D = $Handle

@onready var camera: Camera3D = $Camera_Controller/Camera_Target/Camera3D

const ROTATION_SPEED = 2.0 # Adjust rotation speed as needed

const MAX_X_PULSE = 30
const MAX_Y_PULSE = 20
const MAX_TORQUE = 30

var selected : bool = false

var pulse : Vector3
var torque : Vector3

var start_position : Vector3
var end_position : Vector3


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Skeleton3D/SkeletonIK3D.start()

func _physics_process(delta: float) -> void:	
	#Make camera controller match position of self
	$Camera_Controller.position = lerp($Camera_Controller.position, position, .05)
	
	# reset position
	if Input.is_action_pressed("reset_position"):
		self.position = Vector3(0, 0, 0)  # Reset position to (0, 0, 0)
		self.rotation_degrees = Vector3(0, 0, 0)  # Reset rotation to (0, 0, 0)
		self.linear_velocity = Vector3(0, 0, 0)  # Stop linear momentum
		self.angular_velocity = Vector3(0, 0, 0)  # Stop angular momentum

#stop all motion
func stop_motion() -> void:
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	sleeping = true
	
# given a pulse and torque apply force and rotation to the sword
func shoot(pulse:Vector3, torque:Vector3)->void:	
	# Reset linear and angular velocity so to not "stack" impulses
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	
	self.apply_impulse(pulse) # just need x and y values
	self.apply_torque_impulse(torque) # just need z value


func _on_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	
	#isten for mouse buttons
	if event is InputEventMouseButton:
		
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			selected = true
			
		elif event.is_released() and event.button_index == MOUSE_BUTTON_LEFT and selected:
			
			#reset handle position
			handle.position = Vector3(0,5,0)
			
			var areaCollision = camera.shoot_ray()
			print("Mouse released at position Ray:", areaCollision)
			
			
			# upward force between 5 and 0. the closer to 0 the stronger torque and more lift



			# Calculate launching values
			if areaCollision. x <= 0:
				pulse = Vector3(30,20,0)
				torque = Vector3(0,0,-30)
			else:
				pulse = Vector3(-30,20,0)
				torque = Vector3(0,0,30)
				
		
			#pulse = pulse.limit_length(MAX_PULSE)
			#torque = torque.limit_length(MAX_TORQUE)

			# Shoot
			shoot(pulse, torque)
			print("Shoot with pulse:", pulse)
			print("Shoot with torque:", torque)
			selected = false
			
	#raycast from camer to mouse position (x, y, 0)
	#check if colliding with bendableArea
	#if colliding, handle position = mouse position
	if event is InputEventMouseMotion and selected:
		var areaCollision = camera.shoot_ray()
		if areaCollision is Vector3:
			# add 5 to y because that is the Handle's offset
			handle.position = Vector3(areaCollision.x, areaCollision.y + 5, handle.position.z)



func _on_sword_tip_area_body_entered(_body: Node3D) -> void:
	print("STAB")
	stop_motion() # Replace with function body.
