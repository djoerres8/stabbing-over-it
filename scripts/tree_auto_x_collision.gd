extends StaticBody3D

func _ready():
	# Create a CollisionPolygon3D to hold the combined shape
	var collision_polygon = CollisionPolygon3D.new()
	add_child(collision_polygon)

	var combined_points = []

	# Recursively process all child MeshInstance3D nodes
	process_mesh_instances(self, combined_points)

	if combined_points.size() > 0:
		# Generate the convex hull for all collected points
		var hull = Geometry.convex_hull_2d(combined_points)
		
		# Convert 2D points back to 3D with z=0
		var final_points = []
		for point in hull:
			final_points.append(Vector3(point.x, point.y, 0))
		
		# Assign the combined polygon to the CollisionPolygon3D
		collision_polygon.polygon = final_points
	else:
		print("No valid meshes found to process.")

func process_mesh_instances(node: Node3D, points: Array):
	# Recursively find all MeshInstance3D children
	for child in node.get_children():
		if child is MeshInstance3D and child.mesh:
			var mesh = child.mesh
			if mesh is ArrayMesh:
				# Process each surface of the mesh
				for surface_index in mesh.get_surface_count():
					var arrays = mesh.surface_get_arrays(surface_index)
					var vertices = arrays[Mesh.ARRAY_VERTEX]
					for vertex in vertices:
						var point_2d = Vector2(vertex.x, vertex.y)
						if point_2d not in points:
							points.append(point_2d)
			else:
				print("Skipping non-ArrayMesh on", child.name)
		elif child is Node3D:
			# Recurse into other Node3D children
			process_mesh_instances(child, points)
