extends CharacterBody3D


const SPEED = 5.0 #movement
const ROTATION_SPEED = 2.0 # Adjust rotation speed as needed

const JUMP_ACCELERATION = 10
const JUMP_MAX = 10
var jump_velocity = 0
var is_space_held = true


func _physics_process(delta: float) -> void:
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Check if the spacebar is held down
	if Input.is_action_pressed("ui_accept"):
		is_space_held = true
		if jump_velocity < JUMP_MAX:
			jump_velocity += JUMP_ACCELERATION * delta
			print("charging jump to: " + str(jump_velocity))
	
	# Check if the spacebar is released
	elif is_space_held and Input.is_action_just_released("ui_accept"):
		is_space_held = false
		# Execute the jump or apply the velocity
		velocity.y = jump_velocity
		jump_velocity = 0.0 # Reset the jump velocity for the next jump

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "", "")
	var direction := (transform.basis * Vector3(input_dir.x, 0, 0)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	  # Handle rotation using up and down keys
	if Input.is_action_pressed("ui_up"):
		rotation.z -= ROTATION_SPEED * delta
	elif Input.is_action_pressed("ui_down"):
		rotation.z += ROTATION_SPEED * delta

	#apply movement
	#velocity.z = move_toward(velocity.z, 0, SPEED) # Optional if you want deceleration along the Z-axis
	move_and_slide()
	
	#Make camera controller match position of self
	$Camera_Controller.position = lerp($Camera_Controller.position, position, .05)
	
	
	
	
	
	
	
	
	
	
	
	
	
