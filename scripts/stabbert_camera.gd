extends Camera3D

func shoot_ray():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_length = 100
	var from = project_ray_origin(mouse_pos) 
	var to = from + project_ray_normal(mouse_pos) * ray_length
	var space = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.create(from,to,2)
	
	# we want to detect the bendable are so only look for areas
	ray_query.collide_with_areas = true
	ray_query.collide_with_bodies = false
	
	var raycast_result = space.intersect_ray(ray_query)
	if raycast_result:
		var collision_position = raycast_result.position  # World position of the collision
		var collision_area = raycast_result.collider      # The collided area (Area3D)
		var relative_position = collision_area.to_local(collision_position)
		return relative_position
	return raycast_result
		
	
