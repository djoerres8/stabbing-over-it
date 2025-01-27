extends AnimatableBody3D

var rotation_speed = 10.0

func _physics_process(delta: float) -> void:
	self.rotate_z(deg_to_rad(rotation_speed * delta))
