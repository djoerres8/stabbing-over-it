extends RigidBody3D

@onready var sword_tip: CollisionShape3D = $"CollisionShape3D-tip"

# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#if sword_tip != null:
		#var tip_collision = get_node(sword_tip)
		#tip_collision.connect("body_entered", self, "_on_tip_collision")
#
#func _on_tip_collision(body):
	#if body.is_in_group("floor"): # Assuming the floor is in a "floor" group
		## Stop the sword by setting its velocity to zero
		#linear_velocity = Vector3.ZERO
		#angular_velocity = Vector3.ZERO
