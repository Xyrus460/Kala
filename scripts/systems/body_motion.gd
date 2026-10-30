extends RefCounted

static func move(body: CharacterBody3D, delta: float, step_height = 0.38) -> void:
	var start = body.global_transform
	var grounded = body.is_on_floor()
	var requested = body.velocity
	var horizontal = Vector3(requested.x, 0, requested.z) * delta
	body.move_and_slide()
	if not grounded or horizontal.length() < 0.005: return
	var moved = body.global_position - start.origin; moved.y = 0
	if moved.length() > horizontal.length() * 0.55: return
	# CharacterBody cannot step up mesh stair risers by itself. Raise only when
	# the full capsule fits and a walkable landing exists within one step.
	for height in [0.16, 0.28, step_height]:
		var raised = start; raised.origin.y += height
		if body.test_move(start, Vector3.UP * height) or body.test_move(raised, horizontal): continue
		# Probe beyond the capsule's leading edge. A centre-only ray still sees
		# the lower tread while the rounded capsule is already touching a riser.
		var top = raised.origin + horizontal + horizontal.normalized() * 0.42 + Vector3.UP * 0.05
		var query = PhysicsRayQueryParameters3D.create(top, top - Vector3.UP * (height + 0.26), 1)
		query.exclude = [body.get_rid()]
		var hit = body.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or hit.normal.y < 0.65 or hit.position.y < start.origin.y - 0.1: continue
		body.global_transform = raised; body.velocity = requested
		body.move_and_slide(); body.apply_floor_snap()
		return
