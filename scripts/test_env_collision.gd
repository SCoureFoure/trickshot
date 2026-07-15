extends SceneTree

## Headless test suite for environment collision shapes. Run:
## godot --headless --xr-mode off --path . --script res://scripts/test_env_collision.gd

var _failures := 0


func _check(name: String, cond: bool) -> void:
	if cond:
		print("PASS: " + name)
	else:
		_failures += 1
		print("FAIL: " + name)


func _initialize() -> void:
	_test_asset_collision_shapes()
	_test_tree_gltf_collision_free()
	_test_mountain_collision_free()
	_test_range_environment_direct_children()
	_test_range_environment_collision_count()
	_test_range_environment_tree_wrappers()
	await _test_tree_wrapper_shapes("res://scenes/env/tree_a.tscn", 0.54, 1.92)
	await _test_tree_wrapper_shapes("res://scenes/env/tree_b.tscn", 0.57, 2.28)
	await _test_tree_scale_propagation()
	await _test_canopy_drag_slows_ball()
	if _failures == 0:
		print("ALL_PASS")
		quit(0)
	else:
		print("FAILURES=%d" % _failures)
		quit(1)


func _test_asset_collision_shapes() -> void:
	# Assets expecting ConcavePolygonShape3D
	var concave_assets := [
		"res://assets/kaykit_hex/building_archeryrange_red.gltf",
		"res://assets/kaykit_hex/tent.gltf",
		"res://assets/kaykit_hex/weaponrack.gltf",
	]

	# Assets expecting ConvexPolygonShape3D
	var convex_assets := [
		"res://assets/kaykit_hex/bucket_arrows.gltf",
		"res://assets/kaykit_hex/barrel.gltf",
		"res://assets/kaykit_hex/sack.gltf",
		"res://assets/kaykit_hex/rock_single_C.gltf",
		"res://assets/kaykit_hex/wall_straight.gltf",
	]

	# Test concave assets
	for asset_path in concave_assets:
		var ps: PackedScene = load(asset_path)
		if ps == null:
			_check(_get_asset_name(asset_path) + " loads", false)
			continue

		var instance: Node = ps.instantiate()
		var has_shape := _has_collision_shape_class(instance, "ConcavePolygonShape3D")
		_check(_get_asset_name(asset_path) + " has ConcavePolygonShape3D", has_shape)
		instance.free()

	# Test convex assets
	for asset_path in convex_assets:
		var ps: PackedScene = load(asset_path)
		if ps == null:
			_check(_get_asset_name(asset_path) + " loads", false)
			continue

		var instance: Node = ps.instantiate()
		var has_shape := _has_collision_shape_class(instance, "ConvexPolygonShape3D")
		_check(_get_asset_name(asset_path) + " has ConvexPolygonShape3D", has_shape)
		instance.free()


func _test_tree_gltf_collision_free() -> void:
	var tree_gltfs := [
		"res://assets/kaykit_hex/tree_single_A.gltf",
		"res://assets/kaykit_hex/tree_single_B.gltf",
	]
	for asset_path in tree_gltfs:
		var ps: PackedScene = load(asset_path)
		if ps == null:
			_check(_get_asset_name(asset_path) + " loads", false)
			continue

		var instance: Node = ps.instantiate()
		var collision_count := _count_collision_shapes(instance)
		_check(_get_asset_name(asset_path) + " has zero CollisionShape3D", collision_count == 0)
		instance.free()


func _test_mountain_collision_free() -> void:
	var ps: PackedScene = load("res://assets/kaykit_hex/mountain_A.gltf")
	if ps == null:
		_check("mountain_A loads", false)
		return

	var instance: Node = ps.instantiate()
	var collision_count := _count_collision_shapes(instance)
	_check("mountain_A has zero CollisionShape3D", collision_count == 0)
	instance.free()


func _test_range_environment_direct_children() -> void:
	var ps: PackedScene = load("res://scenes/range_environment.tscn")
	if ps == null:
		_check("range_environment loads", false)
		return

	var instance: Node3D = ps.instantiate()
	var has_static_body := false
	for child in instance.get_children():
		if child is StaticBody3D:
			has_static_body = true
			break
	_check("range_environment zero direct StaticBody3D children", not has_static_body)
	instance.free()


func _test_range_environment_collision_count() -> void:
	var ps: PackedScene = load("res://scenes/range_environment.tscn")
	if ps == null:
		_check("range_environment loads", false)
		return

	var instance: Node = ps.instantiate()
	var collision_count := _count_collision_shapes(instance)
	_check("range_environment has at least 15 CollisionShape3D", collision_count >= 15)
	instance.free()


func _test_range_environment_tree_wrappers() -> void:
	var ps: PackedScene = load("res://scenes/range_environment.tscn")
	if ps == null:
		_check("range_environment loads", false)
		return

	var instance: Node3D = ps.instantiate()
	var tree_a1: Node = instance.get_node_or_null("TreeA1")
	var tree_b2: Node = instance.get_node_or_null("TreeB2")
	_check("range_environment TreeA1 uses tree_drag.gd", tree_a1 != null and tree_a1.get_script() != null and (tree_a1.get_script() as Script).resource_path == "res://scripts/tree_drag.gd")
	_check("range_environment TreeB2 uses tree_drag.gd", tree_b2 != null and tree_b2.get_script() != null and (tree_b2.get_script() as Script).resource_path == "res://scripts/tree_drag.gd")
	instance.free()


func _test_tree_wrapper_shapes(scene_path: String, trunk_radius: float, canopy_radius: float) -> void:
	var name := _get_asset_name(scene_path)
	var ps: PackedScene = load(scene_path)
	if ps == null:
		_check(name + " loads", false)
		return

	var inst: Node3D = ps.instantiate()
	get_root().add_child(inst)
	await process_frame

	var trunk_shape_node: CollisionShape3D = inst.get_node_or_null("Trunk/CollisionShape3D")
	var trunk_shape: Shape3D = trunk_shape_node.shape if trunk_shape_node else null
	_check(name + " trunk shape is CylinderShape3D", trunk_shape is CylinderShape3D)
	if trunk_shape is CylinderShape3D:
		_check(name + " trunk radius matches", is_equal_approx_tol((trunk_shape as CylinderShape3D).radius, trunk_radius))

	var canopy: Area3D = inst.get_node_or_null("Canopy")
	_check(name + " canopy is Area3D", canopy is Area3D)
	if canopy is Area3D:
		_check(name + " canopy linear_damp_space_override is COMBINE", canopy.linear_damp_space_override == Area3D.SPACE_OVERRIDE_COMBINE)
		_check(name + " canopy linear_damp matches", is_equal_approx_tol(canopy.linear_damp, 1.2))
		_check(name + " canopy collision_mask includes layer 1", (canopy.collision_mask & 1) != 0)

	var canopy_shape_node: CollisionShape3D = inst.get_node_or_null("Canopy/CollisionShape3D")
	var canopy_shape: Shape3D = canopy_shape_node.shape if canopy_shape_node else null
	_check(name + " canopy shape is CylinderShape3D", canopy_shape is CylinderShape3D)
	if canopy_shape is CylinderShape3D:
		_check(name + " canopy radius matches", is_equal_approx_tol((canopy_shape as CylinderShape3D).radius, canopy_radius))

	get_root().remove_child(inst)
	inst.free()


func _test_tree_scale_propagation() -> void:
	var ps: PackedScene = load("res://scenes/env/tree_a.tscn")
	if ps == null:
		_check("tree_a loads for scale test", false)
		return

	var inst: Node = ps.instantiate()
	inst.tree_scale = 7.0
	get_root().add_child(inst)
	await process_frame

	var trunk_shape_node: CollisionShape3D = inst.get_node_or_null("Trunk/CollisionShape3D")
	var trunk_shape: Shape3D = trunk_shape_node.shape if trunk_shape_node else null
	_check("tree_a trunk radius scales with tree_scale", trunk_shape is CylinderShape3D and is_equal_approx_tol((trunk_shape as CylinderShape3D).radius, 0.63))

	get_root().remove_child(inst)
	inst.free()


func _test_canopy_drag_slows_ball() -> void:
	var tree_ps: PackedScene = load("res://scenes/env/tree_a.tscn")
	if tree_ps == null:
		_check("tree_a loads for sim test", false)
		return

	var tree: Node3D = tree_ps.instantiate()
	get_root().add_child(tree)

	var canopy_ball := _make_ball(Vector3(0, 0.6 * 6.0, 0))
	var control_ball := _make_ball(Vector3(0, 50, 0))
	get_root().add_child(canopy_ball)
	get_root().add_child(control_ball)

	for i in 40:
		await physics_frame

	var control_speed := control_ball.linear_velocity.length()
	var canopy_speed := canopy_ball.linear_velocity.length()
	_check("control ball speed > 7.3 (only ambient damping)", control_speed > 7.3)
	_check("canopy ball speed slowed but not stopped (>4.5 and <6.9)", canopy_speed > 4.5 and canopy_speed < 6.9)

	canopy_ball.free()
	control_ball.free()
	get_root().remove_child(tree)
	tree.free()


func _make_ball(pos: Vector3) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.gravity_scale = 0.0
	body.position = pos
	body.linear_velocity = Vector3(8, 0, 0)
	var shape_node := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.1
	shape_node.shape = sphere
	body.add_child(shape_node)
	return body


func is_equal_approx_tol(a: float, b: float) -> bool:
	return abs(a - b) < 0.001


func _get_asset_name(path: String) -> String:
	var parts := path.split("/")
	var filename := parts[-1] as String
	return filename.trim_suffix(".gltf")


func _has_collision_shape_class(node: Node, expected_class: String) -> bool:
	var stack: Array = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is CollisionShape3D:
			var shape: Shape3D = (current as CollisionShape3D).shape
			if shape and shape.get_class() == expected_class:
				return true
		stack.append_array(current.get_children())
	return false


func _count_collision_shapes(node: Node) -> int:
	var count := 0
	var stack: Array = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is CollisionShape3D:
			count += 1
		stack.append_array(current.get_children())
	return count
