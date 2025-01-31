extends Node3D

@onready var cloud_1: Node3D = $cloud1
@onready var cloud_2: Node3D = $cloud2
@onready var cloud_3: Node3D = $cloud3
@onready var cloud_4: Node3D = $cloud4

var rotation_speed = 10.0  # Speed in degrees per second
var orbit_radius = 7.0  # Distance from center
var angle = 0.0  # Tracking the current rotation angle

func _physics_process(delta: float) -> void:
	
	angle += rotation_speed * delta
	var rad_angle = deg_to_rad(angle)

	var clouds = [cloud_1,  cloud_3, cloud_2, cloud_4]
	var num_clouds = clouds.size()

	for i in range(num_clouds):
		var cloud_angle = rad_angle + i * TAU / num_clouds  # Distribute evenly in a circle
		var new_x = orbit_radius * cos(cloud_angle)
		var new_y = orbit_radius * sin(cloud_angle)  # Rotate in X-Y plane, keeping Z fixed
		clouds[i].position = Vector3(new_x, new_y, clouds[i].position.z)  # Keep Z unchanged
