extends RigidBody3D

@onready var hud: CanvasLayer = $"../Hud"

#controls the bending of the sword when dragging
@onready var handle: Node3D = $Handle
@onready var debug_mesh: ImmediateMesh = ImmediateMesh.new()
@onready var left_hilt_ray: RayCast3D = $LeftHiltRay
@onready var right_hilt_ray: RayCast3D = $RightHiltRay

#sfx
@onready var sword_flying: AudioStreamPlayer = $SFX/swordFlying
@onready var tip_wood: AudioStreamPlayer = $SFX/tipWood
@onready var body_wood: AudioStreamPlayer = $SFX/bodyWood
@onready var tip_ground: AudioStreamPlayer = $SFX/tipGround
@onready var body_ground: AudioStreamPlayer = $SFX/bodyGround
@onready var tip_stone: AudioStreamPlayer = $SFX/tipStone
@onready var body_stone: AudioStreamPlayer = $SFX/bodyStone
@onready var tip_cloud: AudioStreamPlayer = $SFX/tipCloud
@onready var body_cloud: AudioStreamPlayer = $SFX/bodyCloud
@onready var tip_sand: AudioStreamPlayer = $SFX/tipSand
@onready var body_sand: AudioStreamPlayer = $SFX/bodySand
@onready var solid_sword_tip: CollisionPolygon3D = $solidSwordTip
@onready var sword_tip_area: Area3D = $SwordTipArea

const start_position: Vector3 = Vector3(-7.402, 50.056, 0)
#const start_position: Vector3 = Vector3(160.36, 177.72, 0)
#var debug = true
var debug = false

# Minimum and maximum volume settings
var MAX_VOL: float = -5.0 # Loudest
var MIN_VOL: float = -25.0 # verrry quite
const MAX_SPD_FOR_VOL: float = 30.0 # max speed for volume calculation

const GRAVITY_SCALE = 3
const MANUAL_ROTATION_SPEED = 10 # Adjust rotation speed as needed

const MAX_X_AREA = 5
const MIN_X_AREA = -5
const MAX_Y_AREA = 6
const MIN_Y_AREA = -3

const MAX_X_PULSE = 40
const MAX_Y_PULSE = 50
const MIN_Y_PULSE = 5
const MAX_TORQUE = 30

var pulse : Vector3
var torque : Vector3

#vairable that holds if the user is holding the left mouse button and and bending the sword
var selected : bool = false

#wether or not stabbert is currently impaling a surface
var stabbed : bool = false
var unstabbable : int = 0;

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
	
	##temp debug
	if debug:
		freeze = false
		$Camera_Controller/Camera_Target/Camera3D.position = Vector3(-1.958, 0, 0)
		hud.started = true
	
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
	#if selected and not flinging:
		#draw_launch_box()
		
	#get if tip is coliding with anything. this prevents the sliding bug
	var bodies = sword_tip_area.get_overlapping_bodies()
	
	#stop linear motion if impaled
	if stabbed or (bodies.size() > 0 and unstabbable == 0):
		stop_motion()
	else:
		sword_flying.volume_db += -.5
		
	if unstabbable > 0:
		unstabbable -= 1
		
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


	# reset game
	if Input.is_action_pressed("reset_position"):
		reset_position()
		reset_hud()
		
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
	
	#create unstabable frames to not slide along ground
	unstabbable = 5
	
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
	
	#iterate number of flings
	hud.count_fling()
	

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
					torque_z = torque_z - (.4 * pulse_y)
				else:
					torque_z = torque_z + (.4 * pulse_y)

			#set pulse and torque
			torque = Vector3(0, 0, torque_z)
			pulse = Vector3((pulse_x*-1), (pulse_y*-1), 0)
			
			#get animation positions and start fling
			flingPos2 = get_midpoint(handle.position, handleBasePos)
			flingPos1 = get_midpoint(handle.position, flingPos2)
			flingPos3 = get_midpoint(flingPos2, handleBasePos)
			flinging = true
			handlePos = 1
			
			#play sound
			var speed = pulse.length() if pulse.length() > torque.length() else torque.length()
			#60 = max speed
			sword_flying.volume_db = lerp(-45, -14, clamp(speed / 60, 0.0, 1.0))
			sword_flying.pitch_scale = .5 #if speed > 20 else .33
			sword_flying.play()
			
			#remove guidelines
			debug_mesh.clear_surfaces()

#when sword tip enters a body
func _on_sword_tip_area_body_entered(body: Node3D) -> void:
	var material = body.get_meta("material") if body.has_meta("material") else "ground"
	stabbed = true
	play_sound("tip", material)
	sword_flying.stop()
	stop_motion()
	
	#handles when stabbert hits a moving obj
	if body is AnimatableBody3D:
		moving_body = body
		is_on_moving_obj = true
		relative_transform = moving_body.global_transform.affine_inverse() * global_transform


#when the sword tip exits a body
func _on_sword_tip_area_body_exited(_body: Node3D) -> void:
	continue_motion()
	stabbed = false
	is_on_moving_obj = false
	
#dont stick to obsidian materials. This works because obsidian wall are set to collision layer and mask 3 & 1 and the moniter area in stabbert is only set to 3
var overlapping_bodies: Array = []

# dont stick
func _on_solid_sword_tip_body_entered(body: Node3D) -> void:
	if body not in overlapping_bodies:
		overlapping_bodies.append(body)

	solid_sword_tip.set_deferred("disabled", false)
	sword_tip_area.set_deferred("monitoring", false)

func _on_solid_sword_tip_body_exited(body: Node3D) -> void:
	if body in overlapping_bodies:
		overlapping_bodies.erase(body)

	# Only disable if no overlapping bodies remain
	if overlapping_bodies.is_empty():
		solid_sword_tip.set_deferred("disabled", true)
		sword_tip_area.set_deferred("monitoring", true)
	
	
# if spin out of wall, and holding bent, you can flip from air
##SOUND EFFECTS

#any other collision occurs, play sound
func _on_sword_collisions_body_entered(body: Node3D) -> void:
		
	var material = body.get_meta("material") if body.has_meta("material") else "ground"
	play_sound("body", material)
	#stop sword flying sound
	sword_flying.stop()

#play sound based on sword part and coliding material volume based on speed of contact
func play_sound(swordPart: String, material: String, _speedBased: bool = true) -> void:
	
	var sound
	# Minimum and maximum volume settings
	MAX_VOL = -5.0 # Loudest
	MIN_VOL = -25.0 # verrry quite
	
	match material:
		"ground":
			if swordPart == "tip":
				sound = tip_ground
			else:
				sound = body_ground
				MAX_VOL = -5.0
				MIN_VOL = -30.0
		"sand":
			sound = tip_sand if swordPart == "tip" else body_sand
		"wood":
			if swordPart == "tip":
				sound = tip_wood
			else:
				sound = body_wood
				MAX_VOL = -5.0
				MIN_VOL = -30.0
		"stone":
			sound = tip_stone if swordPart == "tip" else body_stone
		"cloud":
			#sound = tip_cloud if swordPart == "tip" else body_cloud
			if swordPart == "tip":
				sound = tip_cloud
			else:
				sound = body_cloud
				
			MAX_VOL = 5.0
			MIN_VOL = -20.0
		_:
			sound = tip_ground if swordPart == "tip" else body_ground
	
	
	# Map the total speed to the volume range get whichever is greater angularV or linearV
	if _speedBased:
		var speed = linear_velocity.length() if linear_velocity.length() > angular_velocity.length() else angular_velocity.length()
		sound.volume_db = lerp(MIN_VOL, MAX_VOL, clamp(speed / MAX_SPD_FOR_VOL, 0.0, 1.0))
	
	sound.play()

##GUIDELINES

func draw_launch_direction(projected_pulse: Vector3):
	# Clear any previously drawn surfaces
	debug_mesh.clear_surfaces()
	
	# Start creating the curved rectangle
	debug_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	# Set color (optional)
	debug_mesh.surface_set_color(Color(1, 1, 1, 1))  # Red color

	var num_points = 10  # Number of points in the curve
	var time_step = 0.05  # Small time increment for simulation
	var position = Vector3.ZERO
	var velocity = projected_pulse  # Initial velocity
	#var width = 0.5  # Width of the rectangle

	for i in range(num_points):
		velocity.y -= 9.8 * GRAVITY_SCALE * time_step  # Gravity effect
		debug_mesh.surface_add_vertex(position)
		position += velocity * time_step
		
	# Finish drawing the shape
	debug_mesh.surface_end()

	
#display launch box bounds
func draw_launch_box():
	
	# Start creating the line geometry
	debug_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	# Set line color
	debug_mesh.surface_set_color(Color(1, 1, 0, 1))

	# Define the box vertices
	var v1 = Vector3(-5, -3, 0)            # Bottom-left
	var v2 = Vector3(-5, 6, 0)            # Top-left
	var v3 = Vector3(5, 6, 0)            # Top-right
	var v4 = Vector3(5, -3, 0)            # Bottom-right

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
	
##Reseting

#reset time and flings and won back to 0.
func reset_hud() -> void:
	hud.time = 0.0
	hud.flings = 0
	hud.finished = false
	
#reset position to start and realign
func reset_position() -> void:
	stabbed = false
	self.position = start_position  # Reset position to (0, 0, 0)
	self.rotation_degrees = Vector3(0, 0, 0)  # Reset rotation to (0, 0, 0)
	self.linear_velocity = Vector3(0, 0, 0)  # Stop linear momentum
	self.angular_velocity = Vector3(0, 0, 0)  # Stop angular momentum
	
# reset position if enter bottom of world
func _on_reset_area_body_entered(body: Node3D) -> void:
	reset_position()
