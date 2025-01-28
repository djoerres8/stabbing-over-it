extends RigidBody3D

@onready var play: MeshInstance3D = $Play
@onready var stabbert: RigidBody3D = $"../../stabbert"
@onready var camera_3d: Camera3D = $"../../stabbert/Camera_Controller/Camera_Target/Camera3D"
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var hud: CanvasLayer = $"../../Hud"

var COLOR
var target_position = Vector3(-1.958, 0, 0)
var move_speed = 2.0 # Speed of the movement
var moving = false
var applyTorque = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	COLOR = play.mesh.surface_get_material(0).albedo_color

#for some reason the torque does not react right away, so wait 3 physics frames then apply it
func _physics_process(delta: float) -> void:	
	if applyTorque < 3 and applyTorque != 0:
		if applyTorque == 2:
			self.apply_torque_impulse(Vector3(3, 0, 1)) 
		applyTorque += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if moving:
		# Smoothly move the camera towards the target position
		camera_3d.position = camera_3d.position.lerp(target_position, move_speed * delta)
		# Stop moving when close enough
		if camera_3d.position.distance_to(target_position) < 0.01:
			camera_3d.position = target_position
			moving = false

func _on_area_3d_2_mouse_entered() -> void:
	if play.mesh and play.mesh.surface_get_material(0):
		var material = play.mesh.surface_get_material(0).duplicate()
		material.albedo_color = Color(1, 1, 1) 
		play.mesh.surface_set_material(0, material)


func _on_area_3d_2_mouse_exited() -> void:
	if play.mesh and play.mesh.surface_get_material(0):
		var material = play.mesh.surface_get_material(0).duplicate()
		material.albedo_color = COLOR
		play.mesh.surface_set_material(0, material)

# Play button Pressed!
func _on_area_3d_2_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.is_released() and event.button_index == MOUSE_BUTTON_LEFT:
			stabbert.freeze = false
			self.freeze = false
			moving = true
			audio_stream_player.play()
			self.apply_impulse(Vector3(5, 0, -10))
			applyTorque = 1
			
			#start timer
			hud.started = true
			
