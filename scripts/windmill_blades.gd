extends StaticBody3D

@onready var blades: MeshInstance3D = $RootNode/Windmill_SecondAge
@onready var blades_collision: CollisionPolygon3D = $CollisionPolygon3D

# Rotation speed (degrees per second)
var rotation_speed = 10.0

func _process(delta: float) -> void:
	pass
	# Calculate the rotation angle
	var angle = rotation_speed * delta
	
	# Rotate the blades
	blades.rotate_y(deg_to_rad(angle)) # Adjust axis as per your blade's orientation

	# Rotate the CollisionPolygon3D in sync
	blades_collision.rotate_z(deg_to_rad(angle))
