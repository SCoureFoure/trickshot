extends SceneTree

## Headless test suite for ball type variants. Run:
## godot --headless --xr-mode off --path . --script res://scripts/test_ball_types.gd

var _failures := 0

const EXPECTED := {
	"bouncy": {
		"radius": 0.06, "mass": 0.15, "bounce": 0.85, "friction": 0.6,
		"linear_damp": 0.0, "color": Color(0.2, 0.9, 0.3),
	},
	"beach": {
		"radius": 0.25, "mass": 0.05, "bounce": 0.5, "friction": 0.4,
		"linear_damp": 1.5, "color": Color(0.95, 0.35, 0.35),
	},
	"heavy": {
		"radius": 0.14, "mass": 3.0, "bounce": 0.05, "friction": 0.9,
		"linear_damp": 0.0, "color": Color(0.25, 0.25, 0.28),
	},
	"baseball": {
		"radius": 0.037, "mass": 0.145, "bounce": 0.3, "friction": 0.5,
		"linear_damp": 0.0, "color": Color(0.95, 0.95, 0.9),
	},
}


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

	# Part 1: Test module loading
	var bt = load("res://scripts/ball_types.gd")
	_check("module_loads", bt != null)
	_check("module_has_four_types", bt.TYPES.size() == 4)

	# Test each type in the module
	for key in EXPECTED.keys():
		var expected = EXPECTED[key]
		var actual = bt.TYPES[key]

		_check(
			"module_%s_radius_matches" % key,
			abs(actual["radius"] - expected["radius"]) < 0.0001
		)
		_check(
			"module_%s_mass_matches" % key,
			abs(actual["mass"] - expected["mass"]) < 0.0001
		)
		_check(
			"module_%s_bounce_matches" % key,
			abs(actual["bounce"] - expected["bounce"]) < 0.0001
		)
		_check(
			"module_%s_friction_matches" % key,
			abs(actual["friction"] - expected["friction"]) < 0.0001
		)
		_check(
			"module_%s_linear_damp_matches" % key,
			abs(actual["linear_damp"] - expected["linear_damp"]) < 0.0001
		)

		# Check color with per-channel tolerance
		var color_match := true
		var actual_color: Color = actual["color"]
		var expected_color: Color = expected["color"]
		if abs(actual_color.r - expected_color.r) >= 0.01:
			color_match = false
		if abs(actual_color.g - expected_color.g) >= 0.01:
			color_match = false
		if abs(actual_color.b - expected_color.b) >= 0.01:
			color_match = false
		_check("module_%s_color_matches" % key, color_match)

	_check("get_type_unknown_empty", bt.get_type("nope") == {})
	_check("names_has_four", bt.names().size() == 4)

	# Part 2: Test scenes
	for key in EXPECTED.keys():
		var expected = EXPECTED[key]
		var scene: PackedScene = load("res://scenes/balls/ball_%s.tscn" % key)
		_check("%s_scene_loads" % key, scene != null)

		if scene == null:
			continue

		var ball = scene.instantiate()
		root.add_child(ball)

		_check("%s_is_rigid_body" % key, ball is RigidBody3D)

		_check(
			"%s_script_is_ball_gd" % key,
			ball.get_script() != null and ball.get_script().resource_path == "res://scripts/ball.gd"
		)

		_check("%s_in_balls_group" % key, ball.is_in_group("balls"))

		_check(
			"%s_collision_layer" % key,
			ball.collision_layer == 5
		)

		# CCD must stay OFF: Godot's ray-based CCD eats bounce on fast impacts.
		# Tunneling is prevented by thick static colliders in main.tscn instead.
		_check(
			"%s_no_ccd" % key,
			ball.continuous_cd == false
		)

		_check(
			"%s_mass_matches" % key,
			abs(ball.mass - expected["mass"]) < 0.0001
		)

		_check(
			"%s_linear_damp_matches" % key,
			abs(ball.linear_damp - expected["linear_damp"]) < 0.0001
		)

		# Check CollisionShape3D
		var collision_shape: CollisionShape3D = ball.get_node("CollisionShape3D")
		_check(
			"%s_collision_shape_is_sphere" % key,
			collision_shape.shape is SphereShape3D and abs(collision_shape.shape.radius - expected["radius"]) < 0.0001
		)

		# Check physics_material_override
		var has_physics_material := ball.physics_material_override != null
		_check("%s_has_physics_material" % key, has_physics_material)

		if has_physics_material:
			_check(
				"%s_bounce_matches" % key,
				abs(ball.physics_material_override.bounce - expected["bounce"]) < 0.0001
			)
			_check(
				"%s_friction_matches" % key,
				abs(ball.physics_material_override.friction - expected["friction"]) < 0.0001
			)

		# Check Mesh color
		var mesh_node: MeshInstance3D = ball.get_node("Mesh")
		var mesh_material: StandardMaterial3D = mesh_node.get_surface_override_material(0)
		var color_match := true
		if mesh_material != null:
			var actual_color: Color = mesh_material.albedo_color
			var expected_color: Color = expected["color"]
			if abs(actual_color.r - expected_color.r) >= 0.01:
				color_match = false
			if abs(actual_color.g - expected_color.g) >= 0.01:
				color_match = false
			if abs(actual_color.b - expected_color.b) >= 0.01:
				color_match = false
		else:
			color_match = false
		_check("%s_mesh_color_matches" % key, color_match)

		ball.queue_free()

	if _failures == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=%d" % _failures)
	quit()
