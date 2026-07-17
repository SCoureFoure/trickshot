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

	_check("no_rack_balls", get_nodes_in_group("balls").size() == 0)

	# Three scoring targets at staggered distances for arrow-drop testing.
	var target_specs := {
		"TargetNear": -5.0,
		"TargetMid": -8.005225,
		"TargetFar": -19.272429,
	}
	var targets := {}
	for tname in target_specs:
		var t = main.get_node_or_null(tname)
		targets[tname] = t
		_check(tname + "_exists", t != null and t.has_signal("target_hit"))
		_check(
			tname + "_is_kaykit_archery",
			t != null
			and t.get_script() != null
			and t.get_script().resource_path == "res://scripts/target.gd"
			and t.get_node_or_null("Mesh") != null
			and t.get_node_or_null("Rings") != null
		)
		_check(
			tname + "_downrange_grounded",
			t != null
			and abs(t.transform.origin.z - target_specs[tname]) < 0.01
			and abs(t.transform.origin.y - 0.577) < 0.001
		)
		var connected_to_main := false
		if t != null:
			for connection in t.get_signal_connection_list("target_hit"):
				if connection["callable"].get_object() == main:
					connected_to_main = true
		_check(tname + "_hit_connected_to_main", connected_to_main)

	var score_label = main.get_node_or_null("ScoreLabel")
	_check(
		"score_label_starts_at_zero",
		score_label != null and score_label is Label3D and score_label.text == "0"
	)

	targets["TargetNear"].target_hit.emit(10)
	_check("score_after_first_hit", score_label.text == "10")
	targets["TargetFar"].target_hit.emit(25)
	_check("score_accumulates_across_targets", score_label.text == "35")

	# Playspace is rotated 90 deg: physical spawn-forward maps to world +X, so
	# the range (world -Z) sits at the player's physical LEFT — the owner sits
	# at a desk and turns left to shoot instead of punching the desk.
	var origin: Node3D = main.get_node("XROrigin3D")
	_check(
		"playspace_rotated_left",
		(origin.transform.basis * Vector3.FORWARD).is_equal_approx(Vector3(1, 0, 0))
		and origin.transform.basis.get_scale().is_equal_approx(Vector3.ONE)
	)
	# Desktop preview compensates: camera must still face the range downrange.
	var cam: Node3D = main.get_node("XROrigin3D/XRCamera3D")
	_check(
		"desktop_camera_faces_range",
		(-cam.global_transform.basis.z).is_equal_approx(Vector3(0, 0, -1))
	)

	_check("has_reset_method", main.has_method("reset_balls"))

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

	var ambience: Node = main.get_node_or_null("Ambience")
	_check(
		"ambience_ready",
		ambience is AudioStreamPlayer
		and ambience.autoplay
		and ambience.stream is AudioStreamMP3
		and ambience.stream.loop
	)

	# Control panel and ball spawn sit at the player's physical 3 o'clock
	# (world +Z): out of the vertical bow envelope in the shooting lane
	# (world -Z) and away from the physical desk (world +X). The ball rack
	# itself was removed (it blocked the player) — balls spawn in mid-air
	# at seated arm's reach.
	_check(
		"panel_out_of_shooting_lane",
		panel.transform.origin.z >= 0.0 and panel.transform.origin.length() < 1.2
	)
	_check(
		"spawn_point_in_seated_reach",
		main.SPAWN_POINT.z > 0.3
		and abs(main.SPAWN_POINT.y - 1.0) < 0.2
		and abs(main.SPAWN_POINT.x) < 1.0
	)

	# Rack retired: it sat in the player's way at 3 o'clock.
	_check("rack_removed", main.get_node_or_null("Rack") == null)

	# Bounce wall retired: range is now target-shooting only.
	_check("bounce_wall_removed", main.get_node_or_null("BounceWall") == null)

	# Anti-tunnel invariant: static colliders must be thick because balls have
	# no CCD (CCD eats bounce). Thin colliders reintroduce clip-through.
	var floor_shape: Shape3D = main.get_node("Floor/CollisionShape3D").shape
	_check("floor_collider_thick", floor_shape is BoxShape3D and floor_shape.size.y >= 1.0)
	# Floor doubles as the valley ground under the distant mountain vista.
	_check(
		"floor_extends_to_vista",
		floor_shape is BoxShape3D and floor_shape.size.x >= 200.0 and floor_shape.size.z >= 200.0
	)

	for n in ["ResetButton"]:
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
	_check("spawn_adds_ball", get_nodes_in_group("balls").size() == 1)
	_check("spawn_unknown_ignored", main.BALL_SCENES.get("nope") == null)
	main.spawn_ball("nope")
	_check("spawn_unknown_adds_nothing", main._spawned.size() == 1)

	for i in range(12):
		main.spawn_ball("baseball")
	_check("spawn_cap_enforced", main._spawned.size() == 10)

	main.reset_scene()
	_check("reset_clears_spawned", main._spawned.size() == 0)
	_check("reset_zeroes_score", main.get_node("ScoreLabel").text == "0")

	main.get_node("Bow").load_arrow()
	main.get_node("OoTBow").load_arrow()
	var displaced = get_nodes_in_group("nockable")[0]
	var displaced_home: Vector3 = displaced.global_position
	displaced.global_position = Vector3(9, 9, 9)
	main.reset_scene()
	_check(
		"reset_unloads_bows",
		main.get_node("Bow")._loaded == false and main.get_node("OoTBow")._loaded == false
	)
	_check(
		"reset_returns_loose_arrow",
		displaced.global_position.distance_to(displaced_home) < 0.001
	)

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
	var oot_bow = main.get_node_or_null("OoTBow")
	_check(
		"oot_bow_present",
		oot_bow != null
		and oot_bow.get_script() != null
		and oot_bow.get_script().resource_path == "res://scripts/oot_bow.gd"
		and oot_bow.second_hand_grab == 2
	)
	_check(
		"oot_bow_stand_present",
		main.get_node_or_null("OoTBowStand") is StaticBody3D
	)
	_check(
		"shader_cache_under_camera",
		main.get_node_or_null("XROrigin3D/XRCamera3D/ShaderCache") != null
	)

	var sky = main.get_node_or_null("Sky3D")
	_check(
		"sky3d_present",
		sky is WorldEnvironment
		and sky.get_script() != null
		and sky.get_script().resource_path == "res://addons/sky_3d/src/Sky3D.gd"
		and sky.environment != null
	)
	_check(
		"sky3d_shadows_disabled",
		sky != null and sky.sun != null and sky.moon != null
		and sky.sun.shadow_enabled == false
		and sky.moon.shadow_enabled == false
	)
	_check("sky3d_time_frozen", sky != null and sky.game_time_enabled == false)
	_check("old_sun_removed", main.get_node_or_null("Sun") == null)

	var stray_arrow = load("res://scenes/arrow.tscn").instantiate()
	main.add_child(stray_arrow)
	bow.global_position = Vector3(3, 3, 3)
	oot_bow.global_position = Vector3(3, 3, 3)
	main.reset_scene()
	_check("reset_clears_arrows", stray_arrow.is_queued_for_deletion())
	_check(
		"reset_returns_bow",
		bow.global_transform.origin.distance_to(Vector3(-0.55, 1.0, -0.35)) < 0.001
	)
	_check(
		"reset_returns_oot_bow",
		oot_bow.global_transform.origin.distance_to(Vector3(0.55, 1.0, -0.35)) < 0.001
	)

	# Range environment internals are covered by test_range_environment_scene.gd
	# (props now carry static collision by design).
	var env = main.get_node_or_null("RangeEnvironment")
	_check("range_environment_present", env != null and env.get_child_count() >= 20)

	_check("arrow_barrel_present", main.get_node_or_null("ArrowBarrel") != null)
	var loose := get_nodes_in_group("nockable")
	_check("loose_arrows_present", loose.size() >= 2)
	# Ammo sits by the KayKit bow (world (-0.55, *, -0.35)); reachable there.
	# Check horizontal proximity only — arrows fall to the barrel/ground, so y
	# is not fixed.
	var bow_xz := Vector2(-0.55, -0.35)
	var all_by_bow := true
	for a in loose:
		var p: Vector3 = a.global_position
		if Vector2(p.x, p.z).distance_to(bow_xz) > 0.6:
			all_by_bow = false
	_check("loose_arrows_by_kaykit_bow", all_by_bow)
	# Must not have auto-snapped into either bow's nock zone on spawn.
	_check(
		"loose_arrows_not_auto_nocked",
		main.get_node("Bow")._loaded == false
		and main.get_node("OoTBow")._loaded == false
	)

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
