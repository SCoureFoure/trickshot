extends SceneTree

## Headless test suite for the Ball scene. Run:
## godot --headless --path . --script res://scripts/test_ball_scene.gd

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
	var scene: PackedScene = load("res://scenes/ball.tscn")
	_check("scene_loads", scene != null)

	var ball = scene.instantiate()
	root.add_child(ball)
	var home: Transform3D = ball.global_transform

	_check("is_rigid_body", ball is RigidBody3D)
	_check(
		"script_is_ball_gd",
		ball.get_script() != null and ball.get_script().resource_path == "res://scripts/ball.gd"
	)
	_check("in_balls_group", ball.is_in_group("balls"))

	var collision_shape: CollisionShape3D = ball.get_node("CollisionShape3D")
	_check(
		"collision_shape_radius",
		collision_shape.shape is SphereShape3D and abs(collision_shape.shape.radius - 0.12) < 0.0001
	)

	_check("mass_is_half_kg", ball.mass == 0.5)

	# Layer 3 is what XRToolsFunctionPickup's grab mask looks for; layer 1
	# keeps the ball colliding with floor/rack/target.
	_check("on_pickable_layer", ball.collision_layer == 5)

	_check(
		"empty_sampler_falls_back",
		ball.release_linear_velocity(Vector3(9, 9, 9)) == Vector3(9, 9, 9)
	)

	ball.sampler.add_sample(0.0, Vector3.ZERO)
	ball.sampler.add_sample(0.1, Vector3(0.3, 0, 0))
	_check(
		"sampler_wins_over_fallback",
		(ball.release_linear_velocity(Vector3.ZERO) - Vector3(3, 0, 0)).length() < 0.001
	)

	ball.global_position = Vector3(5, -10, 5)
	ball.respawn()
	_check(
		"respawn_restores_home",
		ball.global_transform.origin.distance_to(home.origin) < 0.001
	)

	ball.queue_free()

	if _failures == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=%d" % _failures)
	quit()
