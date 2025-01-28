extends MeshInstance3D

const speed: float = 1.0  # Speed of oscillation
const max_angle: float = 60.0  # Maximum angle in degrees
var time: float = 0.0  # Internal time tracker

func _process(delta: float) -> void:
	# Update time
	time += delta * speed
	
	# Calculate the angle using sin wave
	var angle = sin(time) * max_angle  # Keep angle in degrees
	
	# Apply the rotation
	rotation_degrees.z = angle
