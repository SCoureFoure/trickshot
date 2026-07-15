extends SceneTree

## Headless test suite for the range environment dressing. Run:
## godot --headless --xr-mode off --path . --script res://scripts/test_range_environment_scene.gd
##
## Props carry static collision (balls/arrows must not ghost through them),
## every collision body is an unscaled sibling of its prop (shape sizes are
## pre-scaled numbers, never inherited node scale), and the distant vista
## (mountains/hills) is collision-free dressing far outside the play area.

var _failures := 0

# Prop -> paired collision body. Bodies are siblings named <Prop>Body.
const PROP_BODIES := [
	"ArcheryLodge", "Tent", "WeaponRack",
	"ArrowBucketA", "ArrowBucketB",
	"BarrelA", "BarrelB", "SackA",
	"TreeA1", "TreeA2", "TreeA3", "TreeB1", "TreeB2",
	"RockA", "RockB",
	"WallBackA", "WallBackB", "WallBackC",
	"WallSideA", "WallSideB", "WallSideC",
]


func _check(name: String, cond: bool) -> void:
	if cond:
		print("PASS: " + name)
	else:
		_failures += 1
		print("FAIL: " + name)


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var scene: PackedScene = load("res://scenes/range_environment.tscn")
	_check("scene_loads", scene != null)

	var env: Node3D = scene.instantiate()
	root.add_child(env)

	# Decorative (non-scoring) target butts are gone: every target in the
	# world must be a real scoring archery_target instance (lives in main).
	for butt in ["ButtA", "ButtB", "ButtC"]:
		_check(butt + "_removed", env.get_node_or_null(butt) == null)

	for prop_name in PROP_BODIES:
		var prop: Node3D = env.get_node_or_null(prop_name)
		var body: Node3D = env.get_node_or_null(prop_name + "Body")
		_check(prop_name + "_present", prop != null)
		var body_ok := body is StaticBody3D
		_check(prop_name + "_has_body", body_ok)
		if not body_ok or prop == null:
			continue
		# Body carries rotation+translation only; scale lives in the shape
		# numbers. A scaled body basis means the shape is silently double-sized.
		# Tolerance 0.01: hand-authored rotation floats land ~1e-4 off unit
		# scale; the bug this catches is a baked prop scale of 3-7x.
		_check(
			prop_name + "_body_unscaled",
			(body.transform.basis.get_scale() - Vector3.ONE).length() < 0.01
		)
		_check(
			prop_name + "_body_colocated",
			body.transform.origin.distance_to(prop.transform.origin) < 0.001
		)
		var shape_node: Node = body.get_node_or_null("CollisionShape3D")
		var shape: Shape3D = shape_node.shape if shape_node is CollisionShape3D else null
		var thick := false
		if shape is BoxShape3D:
			thick = shape.size.x >= 0.5 and shape.size.y >= 0.5 and shape.size.z >= 0.5
		_check(prop_name + "_collider_thick_box", thick)
		# Trees collide over their full canopy, not just the trunk — balls and
		# arrows must not sail through the foliage (user-reported).
		if prop_name.begins_with("Tree"):
			_check(
				prop_name + "_canopy_covered",
				shape is BoxShape3D and shape.size.x >= 3.0 and shape.size.z >= 3.0
			)

	# Back walls retreat behind the far (z=-16) target; side wall row extends.
	for wall_name in ["WallBackA", "WallBackB", "WallBackC"]:
		var wall: Node3D = env.get_node_or_null(wall_name)
		_check(
			wall_name + "_behind_far_target",
			wall != null and wall.transform.origin.z <= -18.0
		)
	var side_c: Node3D = env.get_node_or_null("WallSideC")
	_check("side_wall_row_extended", side_c != null and side_c.transform.origin.z <= -12.0)

	# Distant vista: mountains + hills grouped under Distant, far away, big,
	# and free of physics bodies and scripts.
	var distant: Node3D = env.get_node_or_null("Distant")
	_check("distant_group_exists", distant != null)
	var mountain_count := 0
	var hill_count := 0
	if distant != null:
		for child in distant.get_children():
			var cname := String(child.name)
			if cname.begins_with("Mountain"):
				mountain_count += 1
				_check(
					cname + "_far_and_big",
					child.transform.origin.z <= -40.0
					and child.transform.basis.get_scale().y >= 15.0
				)
			elif cname.begins_with("Hill"):
				hill_count += 1
				_check(
					cname + "_far",
					child.transform.origin.z <= -30.0
					and child.transform.basis.get_scale().y >= 10.0
				)
	_check("at_least_three_mountains", mountain_count >= 3)
	_check("at_least_two_hills", hill_count >= 2)

	var distant_clean := distant != null
	if distant != null:
		var stack: Array = [distant]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			if node is PhysicsBody3D:
				distant_clean = false
			stack.append_array(node.get_children())
	_check("distant_vista_no_collision", distant_clean)

	# No scripts anywhere: this scene stays logic-free dressing.
	var script_free := true
	var stack: Array = [env]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node.get_script() != null:
			script_free = false
		stack.append_array(node.get_children())
	_check("environment_script_free", script_free)

	env.free()

	if _failures == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=%d" % _failures)
	quit()
