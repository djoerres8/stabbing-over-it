extends RigidBody3D

#controls the bending of the sword when dragging
@onready var handle: Node3D = $Handle
#@onready var camera: Camera3D = $Camera_Controller/Camera_Target/Camera3D
@onready var debug_mesh: ImmediateMesh = ImmediateMesh.new()
@onready var left_hilt_ray: RayCast3D = $LeftHiltRay
@onready var right_hilt_ray: RayCast3D = $RightHiltRay

const GRAVITY_SCALE = 3
const MANUAL_ROTATION_SPEED = 10 # Adjust rotation speed as needed

const MAX_X_AREA = 5
const MIN_X_AREA = -5
const MAX_Y_AREA = 6
const MIN_Y_AREA = -4

const MAX_X_PULSE = 50
const MAX_Y_PULSE = 50
const MIN_Y_PULSE = 5
const MAX_TORQUE = 30

var pulse : Vector3
var torque : Vector3

#vairable that holds if the user is holding the left mouse button and and bending the sword
var selected : bool = false

#wether or not stabbert is currently impaling a surface
var stabbed : bool = false

#track while the sword is being animated from release to fling
var flinging : bool = false
var flingPos1 : Vector3
var flingPos2 : Vector3
var flingPos3 : Vector3
var handleBasePos : Vector3 = Vector3(0,5,0)
var handlePos : int

#handle stabbert on moving objects
var is_on_moving_obj : bool = false
var moving_body: Node3D = null
var relative_transform: Transform3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Skeleton3D/SkeletonIK3D.start()
	# Add a MeshInstance3D to display the ImmediateMesh
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = debug_mesh
	add_child(mesh_instance)

func _physics_process(delta: float) -> void:	
	#Make camera controller match position of self
	$Camera_Controller.position = lerp($Camera_Controller.position, position, .1)

	if stabbed and is_on_moving_obj:
		global_transform = moving_body.global_transform * relative_transform
		
	#launch box
	if selected and not flinging:
		draw_launch_box()
	
	#stop linear motion if impaled
	if stabbed:
		stop_motion()
		
	if stabbed or is_motionless():
			#rotate left/right while stabbed
		if Input.is_action_just_pressed("scroll_down") and not left_hilt_ray.is_colliding():
			rotation.z -= MANUAL_ROTATION_SPEED * delta
		elif Input.is_action_just_pressed("scroll_up") and not right_hilt_ray.is_colliding():
			rotation.z += MANUAL_ROTATION_SPEED * delta
			
	if stabbed or is_motionless():
	# Rotate left/right while stabbed
		if Input.is_action_just_pressed("scroll_down") and not left_hilt_ray.is_colliding():
			# Add manual rotation to the relative transform
			relative_transform.basis = Basis(Vector3(0, 0, 1), -MANUAL_ROTATION_SPEED * delta) * relative_transform.basis
		elif Input.is_action_just_pressed("scroll_up") and not right_hilt_ray.is_colliding():
			# Add manual rotation to the relative transform
			relative_transform.basis = Basis(Vector3(0, 0, 1), MANUAL_ROTATION_SPEED * delta) * relative_transform.basis


	# reset position
	if Input.is_action_pressed("reset_position"):
		self.position = Vector3(0, 5, 0)  # Reset position to (0, 0, 0)
		self.rotation_degrees = Vector3(0, 0, 0)  # Reset rotation to (0, 0, 0)
		self.linear_velocity = Vector3(0, 0, 0)  # Stop linear momentum
		self.angular_velocity = Vector3(0, 0, 0)  # Stop angular momentum
		
	if flinging:
		match handlePos:
			1:
				handle.position = flingPos1
				handlePos += 1
			2:
				handle.position = flingPos2
				handlePos += 1
			3:
				handle.position = flingPos3
				handlePos += 1
			_:
				handle.position = handleBasePos
				flinging = false
				shoot()
		

#stop all motion by setting gravity to 0
func stop_motion() -> void:
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	gravity_scale = 0
	
#Allow sword to continue moving
func continue_motion() -> void:
	stabbed = false
	gravity_scale = GRAVITY_SCALE
	
#check if sword is moveing. using .1 as that seems to be small enough that it wont actually move but the values get stuck lower a lot
func is_motionless() -> bool:
	return (abs(linear_velocity.x) <= 0.1 and abs(linear_velocity.y) <= 0.1)
	
#helper function to get midpoint of 3 vetecies
func get_midpoint(vec1: Vector3, vec2: Vector3) -> Vector3:
	return (vec1 + vec2) / 2

# given a pulse and torque apply force and rotation to the sword
func shoot()->void:	
	
	# allow sword to leave a surface
	continue_motion()
	
	# Reset linear and angular velocity so to not "stack" impulses
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	
	# Calculate the adjusted pulse based on the current z-rotation
	var angle = rotation.z  # Get the object's z-rotation in radians
	var cos_angle = cos(angle)
	var sin_angle = sin(angle)

  # Rotate the pulse vector in the X-Y plane
	var adjusted_pulse = Vector3(
		pulse.x * cos_angle - pulse.y * sin_angle,
		pulse.x * sin_angle + pulse.y * cos_angle,
		pulse.z  # Z stays the same
	)
	
	#Apply force to the sword
	self.apply_impulse(adjusted_pulse) # just need x and y values
	self.apply_torque_impulse(torque) # just need z value
	
	#selected is turned here because we dont want it false before the sword starts moving
	selected = false
	

func _on_area_3d_input_event(camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	#isten for mouse buttons
	if event is InputEventMouseButton:
		
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT and (stabbed or is_motionless()):
			selected = true
			
	#raycast from camer to mouse position (x, y, 0)
	#check if colliding with bendableArea
	#if colliding, handle position = mouse position
	if event is InputEventMouseMotion and selected and not flinging:
		var areaCollision = camera.shoot_ray()
		if areaCollision is Vector3:
			# add 5 to y because that is the Handle's offset
			handle.position = Vector3(areaCollision.x, areaCollision.y + 5, handle.position.z)
			
			#get relative values  
			var pulse_x = ((clamp(areaCollision.x, -5, 5) - MIN_X_AREA) / (MAX_X_AREA - MIN_X_AREA)) * (MAX_X_PULSE*2) - MAX_X_PULSE
			var pulse_y = ((clamp(areaCollision.y+5, -4, 6) - MIN_Y_AREA) / (MAX_Y_AREA - MIN_Y_AREA)) * (MAX_Y_PULSE - MIN_Y_PULSE) - MAX_Y_PULSE			
			draw_launch_direction(Vector3(pulse_x*-1, pulse_y*-1, 0))
		
#listen for lmb release and fling
func _input(event):
			
	if event is InputEventMouseButton:
		if event.is_released() and event.button_index == MOUSE_BUTTON_LEFT and selected:
						
			#get vector the handle is at when releasing
			var area_x = clamp(handle.position.x, MIN_X_AREA, MAX_X_AREA)
			var area_y = clamp(handle.position.y, MIN_Y_AREA, MAX_Y_AREA)
			
			# trandform the vector from where the handle is when releasing to the coresponding value from min-max for x and y
			var pulse_x = ((area_x - MIN_X_AREA) / (MAX_X_AREA - MIN_X_AREA)) * (MAX_X_PULSE*2) - MAX_X_PULSE
			var pulse_y = ((area_y - MIN_Y_AREA) / (MAX_Y_AREA - MIN_Y_AREA)) * (MAX_Y_PULSE - MIN_Y_PULSE) - MAX_Y_PULSE
			
			#calculate pulse relative to the x vector, then add additional depending on how low the y axes is
			var torque_z = ((pulse_x + MAX_X_PULSE) / (MAX_X_PULSE + MAX_X_PULSE)) * (MAX_TORQUE*2) - MAX_TORQUE
			if area_y < 4:
				if torque_z > 0:
					torque_z = torque_z - (.5 * pulse_y)
				else:
					torque_z = torque_z + (.5 * pulse_y)
			
			#set pulse and torque
			torque = Vector3(0, 0, torque_z)
			pulse = Vector3((pulse_x*-1), (pulse_y*-1), 0)
			
			#get animation positions and start fling
			flingPos2 = get_midpoint(handle.position, handleBasePos)
			flingPos1 = get_midpoint(handle.position, flingPos2)
			flingPos3 = get_midpoint(flingPos2, handleBasePos)
			flinging = true
			handlePos = 1
			
			#remove guidelines
			debug_mesh.clear_surfaces()

#when sword tip enters a body
func _on_sword_tip_area_body_entered(body: Node3D) -> void:
	stabbed = true
	stop_motion()
	print("STAB")
	
	#handles when stabbert hits a moving obj
	if body is AnimatableBody3D:
		print(body)
		moving_body = body
		is_on_moving_obj = true
		relative_transform = moving_body.global_transform.affine_inverse() * global_transform


#when the sword tip exits a body
func _on_sword_tip_area_body_exited(_body: Node3D) -> void:
	continue_motion()
	stabbed = false
	print("BYE STAB")
	is_on_moving_obj = false
	
	
##GUIDELINES

#display launch direction
func draw_launch_direction(projected_pulse: Vector3):
	# Clear any previously drawn surfaces
	debug_mesh.clear_surfaces()

	# Start creating the line geometry
	debug_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	# Set line color (optional)
	debug_mesh.surface_set_color(Color(0, 1, 0))

	# Line start (object's position in global space)
	var start = Vector3.ZERO
	debug_mesh.surface_add_vertex(start)

	# Line end (in the direction of the projected_pulse)
	var end = projected_pulse * 10   # Adjust the length as needed
	debug_mesh.surface_add_vertex(end)

	# Finish creating the line
	debug_mesh.surface_end()
	
#display launch box bounds
func draw_launch_box():
	
	# Start creating the line geometry
	debug_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	# Set line color
	debug_mesh.surface_set_color(Color(1, 1, 0, 1))

	# Define the box vertices
	var v1 = Vector3(-5, -4, 0)            # Bottom-left
	var v2 = Vector3(-5, 6, 0)            # Top-left
	var v3 = Vector3(5, 6, 0)            # Top-right
	var v4 = Vector3(5, -4, 0)            # Bottom-right

	# Draw dotted lines for each edge
	draw_dotted_line(v1, v2, 0.5)  # Bottom-left to Top-left
	draw_dotted_line(v2, v3, 0.5)  # Top-left to Top-right
	draw_dotted_line(v3, v4, 0.5)  # Top-right to Bottom-right
	draw_dotted_line(v4, v1, 0.5)  # Bottom-right to Bottom-left
	
	# Finish creating the box
	debug_mesh.surface_end()
	
func draw_dotted_line(start: Vector3, end: Vector3, segment_length: float) -> void:
	var direction = (end - start).normalized()
	var total_length = start.distance_to(end)
	var current_length = 0.0

	while current_length < total_length:
		var segment_start = start + direction * current_length
		var segment_end = start + direction * min(current_length + segment_length, total_length)

		# Skip segments to create a dotted effect
		debug_mesh.surface_add_vertex(segment_start)
		debug_mesh.surface_add_vertex(segment_end)

		current_length += segment_length * 2  # Adjust gap size
	
