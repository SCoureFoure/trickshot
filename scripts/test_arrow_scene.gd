extends SceneTree

## Headless test suite for the Arrow scene. Run:
## godot --headless --xr-mode off --path . --script res://scripts/test_arrow_scene.gd

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
	var scene: PackedScene = load("res://scenes/arrow.tscn")
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

	arrow.fire(20.0)
	_check(
		"fire_sets_velocity",
		(arrow.linear_velocity - (-arrow.global_transform.basis.z * 20.0)).length() < 0.001
	)

	var arrow2 = scene.instantiate()
	root.add_child(arrow2)
	arrow2.stick(Vector3(1, 1, 1))
	_check(
		"stick_freezes",
		arrow2.freeze == true and arrow2.linear_velocity == Vector3.ZERO and arrow2.global_position.distance_to(Vector3(1, 1, 1)) < 0.001
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

	if _failures == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=%d" % _failures)
	quit()
