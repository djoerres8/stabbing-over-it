extends AnimatableBody3D

const move_distance: float = 2.0  # Maximum movement range
const move_speed: float = 1.0  # Speed of movement

var start_x: float = 0.0
var time_elapsed: float = 0.0
var phase_offset: float = 0.0  # Unique phase for each instance

func _ready() -> void:
	start_x = global_transform.origin.x  # Store the initial position
	phase_offset = randf_range(0, TAU)  # Random phase shift (0 to 2π)

func _physics_process(delta: float) -> void:
	time_elapsed += delta * move_speed
	var offset = sin(time_elapsed + phase_offset) * move_distance  # Apply phase shift
	global_transform.origin.x = start_x + offset
