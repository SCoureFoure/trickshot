extends SceneTree

## Headless test suite for the main playground scene. Run:
## godot --headless --path . --script res://scripts/test_playground_scene.gd

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
	var scene: PackedScene = load("res://scenes/main.tscn")
	_check("scene_loads", scene != null)

	var main = scene.instantiate()
	root.add_child(main)

	var left_pickup = main.get_node_or_null("XROrigin3D/LeftController/CollisionHand/FunctionPickup")
	_check(
		"left_function_pickup",
		left_pickup != null
		and left_pickup.get_script() != null
		and left_pickup.get_script().resource_path.ends_with("function_pickup.gd")
	)

	var right_pickup = main.get_node_or_null("XROrigin3D/RightController/CollisionHand/FunctionPickup")
	_check(
		"right_function_pickup",
		right_pickup != null
		and right_pickup.get_script() != null
		and right_pickup.get_script().resource_path.ends_with("function_pickup.gd")
	)

	# Grab must be close-range only: default 0.3 m sphere + 5 m ranged grab
	# made distant objects grabbable (user-reported).
	_check(
		"left_pickup_close_grab_only",
		left_pickup != null
		and left_pickup.grab_distance <= 0.1
		and left_pickup.ranged_enable == false
	)
	_check(
		"right_pickup_close_grab_only",
		right_pickup != null
		and right_pickup.grab_distance <= 0.1
		and right_pickup.ranged_enable == false
	)

	var left_hand = main.get_node_or_null("XROrigin3D/LeftController/CollisionHand/LeftHand")
	_check("has_left_hand", left_hand != null)

	var right_hand = main.get_node_or_null("XROrigin3D/RightController/CollisionHand/RightHand")
	_check("has_right_hand", right_hand != null)

	_check("four_balls_in_group", get_nodes_in_group("balls").size() == 4)

	var target = main.get_node_or_null("Target")
	_check("target_exists", target != null and target.has_signal("target_hit"))

	var score_label = main.get_node_or_null("ScoreLabel")
	_check(
		"score_label_starts_at_zero",
		score_label != null and score_label is Label3D and score_label.text == "0"
	)

	var connections: Array = target.get_signal_connection_list("target_hit")
	var connected_to_main := false
	for connection in connections:
		if connection["callable"].get_object() == main:
			connected_to_main = true
	_check("target_hit_connected_to_main", connected_to_main)

	target.target_hit.emit(10)
	_check("score_after_first_hit", score_label.text == "10")
	target.target_hit.emit(25)
	_check("score_after_second_hit", score_label.text == "35")

	_check("has_reset_method", main.has_method("reset_balls"))

	var b: Node3D = main.get_node("BouncyBall")
	var before: Vector3 = b.global_transform.origin
	b.global_position = Vector3(3, 3, 3)
	main.reset_balls()
	_check(
		"reset_restores_ball",
		b.global_transform.origin.distance_to(before) < 0.001
	)

	var left_controller = main.get_node("XROrigin3D/LeftController")
	var right_controller = main.get_node("XROrigin3D/RightController")
	_check(
		"controller_buttons_wired",
		left_controller.get_signal_connection_list("button_pressed").size() >= 1
		and right_controller.get_signal_connection_list("button_pressed").size() >= 1
	)

	var movement_provider_path := _find_global_class_path("XRToolsMovementProvider")
	var has_movement_provider := false
	if movement_provider_path != "":
		has_movement_provider = _contains_script_inheriting(main, movement_provider_path)
	else:
		has_movement_provider = _contains_name(main, "Movement")
	_check("no_locomotion", not has_movement_provider)

	var panel = main.get_node_or_null("ButtonPanel")
	_check("button_panel_exists", panel != null)

	var wall = main.get_node_or_null("BounceWall")
	_check(
		"bounce_wall_left_of_player",
		wall != null and wall is StaticBody3D and wall.transform.origin.x < 0.0
	)

	# Anti-tunnel invariant: static colliders must be thick because balls have
	# no CCD (CCD eats bounce). Thin colliders reintroduce clip-through.
	var floor_shape: Shape3D = main.get_node("Floor/CollisionShape3D").shape
	_check("floor_collider_thick", floor_shape is BoxShape3D and floor_shape.size.y >= 1.0)
	var wall_shape: Shape3D = main.get_node("BounceWall/CollisionShape3D").shape
	_check("wall_collider_thick", wall_shape is BoxShape3D and wall_shape.size.x >= 1.0)

	for n in ["ResetButton", "BouncySpawnButton", "BeachSpawnButton", "HeavySpawnButton", "BaseballSpawnButton"]:
		var btn = main.get_node_or_null("ButtonPanel/" + n)
		_check(
			n + "_is_area_button",
			btn != null
			and btn.get_script() != null
			and btn.get_script().resource_path.ends_with("interactable_area_button.gd")
		)
		_check(
			n + "_wired",
			btn != null and btn.get_signal_connection_list("button_pressed").size() >= 1
		)

	_check(
		"pokes_on_controllers",
		main.get_node_or_null("XROrigin3D/LeftController/CollisionHand/Poke") != null
		and main.get_node_or_null("XROrigin3D/RightController/CollisionHand/Poke") != null
	)

	# Collision hands give the hands physical presence: the hand body tracks
	# the controller but collides with the world instead of ghosting through.
	var left_chand = main.get_node_or_null("XROrigin3D/LeftController/CollisionHand")
	var right_chand = main.get_node_or_null("XROrigin3D/RightController/CollisionHand")
	_check(
		"collision_hands_present",
		left_chand != null
		and right_chand != null
		and left_chand.get_script() != null
		and left_chand.get_script().resource_path.ends_with("collision_hand.gd")
		and right_chand.get_script() != null
		and right_chand.get_script().resource_path.ends_with("collision_hand.gd")
	)
	_check(
		"collision_hands_collide_mode",
		left_chand != null and left_chand.mode == 2 and right_chand != null and right_chand.mode == 2
	)
	# Hands must not collide with pickables (layer 3, bit value 4): palm and
	# poke bodies shoved the bow/balls around while reaching to grab.
	_check(
		"collision_hands_ignore_pickables",
		left_chand != null and (left_chand.collision_mask & 4) == 0
		and right_chand != null and (right_chand.collision_mask & 4) == 0
	)
	var left_poke = main.get_node_or_null("XROrigin3D/LeftController/CollisionHand/Poke")
	var right_poke = main.get_node_or_null("XROrigin3D/RightController/CollisionHand/Poke")
	_check(
		"pokes_ignore_pickables",
		left_poke != null and (left_poke.mask & 4) == 0
		and right_poke != null and (right_poke.mask & 4) == 0
	)
	_check(
		"pickups_follow_collision_hand",
		left_pickup != null
		and left_pickup.get_parent() == left_chand
		and right_pickup != null
		and right_pickup.get_parent() == right_chand
	)

	main.spawn_ball("bouncy")
	_check("spawn_adds_ball", get_nodes_in_group("balls").size() == 5)
	_check("spawn_unknown_ignored", main.BALL_SCENES.get("nope") == null)
	main.spawn_ball("nope")
	_check("spawn_unknown_adds_nothing", main._spawned.size() == 1)

	for i in range(12):
		main.spawn_ball("baseball")
	_check("spawn_cap_enforced", main._spawned.size() == 10)

	main.reset_scene()
	_check("reset_clears_spawned", main._spawned.size() == 0)
	_check("reset_zeroes_score", main.get_node("ScoreLabel").text == "0")

	var bow = main.get_node_or_null("Bow")
	_check(
		"bow_present",
		bow != null
		and bow.get_script() != null
		and bow.get_script().resource_path == "res://scripts/bow.gd"
		and bow.second_hand_grab == 2
	)
	_check(
		"bow_stand_present",
		main.get_node_or_null("BowStand") is StaticBody3D
	)
	_check(
		"shader_cache_under_camera",
		main.get_node_or_null("XROrigin3D/XRCamera3D/ShaderCache") != null
	)

	var stray_arrow = load("res://scenes/arrow.tscn").instantiate()
	main.add_child(stray_arrow)
	bow.global_position = Vector3(3, 3, 3)
	main.reset_scene()
	_check("reset_clears_arrows", stray_arrow.is_queued_for_deletion())
	_check(
		"reset_returns_bow",
		bow.global_transform.origin.distance_to(Vector3(-0.55, 1.0, -0.35)) < 0.001
	)

	# Range environment is visual dressing only: no scripts, no physics bodies,
	# nothing that could perturb gameplay or the physics membrane.
	var env = main.get_node_or_null("RangeEnvironment")
	var env_clean := env != null and env.get_child_count() >= 20
	if env != null:
		var stack: Array = [env]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			if node is PhysicsBody3D or (node != env and node.get_script() != null):
				env_clean = false
			stack.append_array(node.get_children())
	_check("range_environment_dressing_only", env_clean)

	main.queue_free()

	if _failures == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=%d" % _failures)
	quit()


func _find_global_class_path(class_name_str: String) -> String:
	for entry in ProjectSettings.get_global_class_list():
		if entry["class"] == class_name_str:
			return entry["path"]
	return ""


func _contains_script_inheriting(node: Node, path: String) -> bool:
	var script: Script = node.get_script()
	while script != null:
		if script.resource_path == path:
			return true
		script = script.get_base_script()
	for child in node.get_children():
		if _contains_script_inheriting(child, path):
			return true
	return false


func _contains_name(node: Node, needle: String) -> bool:
	if String(node.name).contains(needle):
		return true
	for child in node.get_children():
		if _contains_name(child, needle):
			return true
	return false
