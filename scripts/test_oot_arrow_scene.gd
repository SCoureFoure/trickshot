extends SceneTree

## Headless test suite for the OoT Arrow scene. Run:
## godot --headless --xr-mode off --path . --script res://scripts/test_oot_arrow_scene.gd

var _failures := 0


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
	var scene: PackedScene = load("res://scenes/oot_arrow.tscn")
	_check("scene_loads", scene != null)

	var arrow = scene.instantiate()
	root.add_child(arrow)

	_check("is_rigid_body", arrow is RigidBody3D)
	_check(
		"script_is_arrow_gd",
		arrow.get_script() != null and arrow.get_script().resource_path == "res://scripts/arrow.gd"
	)
	_check("in_arrows_group", arrow.is_in_group("arrows"))
	_check("on_layer_5", arrow.collision_layer == 5)
	# Nose sits 0.55 m ahead of origin (capsule center z=-0.106, half-height
	# 0.45). The stick raycast runs tip-to-tip, so this must match the capsule.
	_check("tip_length_matches_capsule", abs(arrow.tip_length - 0.55) < 0.001)

	arrow.fire(20.0)
	_check(
		"fire_sets_velocity",
		(arrow.linear_velocity - (-arrow.global_transform.basis.z * 20.0)).length() < 0.001
	)

	var arrow2 = scene.instantiate()
	root.add_child(arrow2)
	arrow2.stick(Vector3(1, 1, 1))
	# Origin lands tip_length - 0.2 = 0.35 behind the hit point along +Z
	# (default orientation): nose buried 0.2 into the surface, long shaft out.
	_check(
		"stick_freezes",
		arrow2.freeze == true
		and arrow2.linear_velocity == Vector3.ZERO
		and arrow2.global_position.distance_to(Vector3(1, 1, 1.35)) < 0.001
	)

	arrow2._physics_process(11.0)
	_check("stuck_arrow_expires", arrow2.is_queued_for_deletion() == true)

	var arrow3 = scene.instantiate()
	root.add_child(arrow3)
	arrow3.fire(5.0)
	arrow3._physics_process(31.0)
	_check("flight_timeout_expires", arrow3.is_queued_for_deletion() == true)

	var arrow4 = scene.instantiate()
	root.add_child(arrow4)
	arrow4.fire(5.0)
	arrow4.global_position = Vector3(0, -10, 0)
	arrow4._physics_process(0.1)
	_check("void_fall_expires", arrow4.is_queued_for_deletion() == true)

	# Flight integration: a fired OoT arrow must stick into a wall it actually
	# hits. This was the user-visible bug: the 0.55 m nose stopped the body
	# while the origin-to-origin raycast never reached the surface, so OoT
	# arrows bounced off targets that KayKit arrows stuck into.
	var wall := StaticBody3D.new()
	var wall_col := CollisionShape3D.new()
	var wall_box := BoxShape3D.new()
	wall_box.size = Vector3(4, 4, 1)
	wall_col.shape = wall_box
	wall.add_child(wall_col)
	wall.position = Vector3(0, 5, -3.5)
	root.add_child(wall)
	var arrow5 = scene.instantiate()
	root.add_child(arrow5)
	arrow5.global_position = Vector3(0, 5, 0)
	arrow5.fire(15.0)
	for i in range(300):
		await physics_frame
		if arrow5.freeze:
			break
	_check("fired_arrow_sticks_in_wall", arrow5.freeze == true)
	_check(
		"stuck_at_wall_face",
		arrow5.freeze and abs(arrow5.global_position.z - (-2.65)) < 0.6
	)

	if _failures == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=%d" % _failures)
	quit()
