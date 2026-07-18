extends SceneTree

## Headless test suite for the OoTBow scene. Run:
## godot --headless --xr-mode off --path . --script res://scripts/test_oot_bow_scene.gd

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
	var scene: PackedScene = load("res://scenes/oot_bow.tscn")
	_check("scene_loads", scene != null)

	var bow = scene.instantiate()
	root.add_child(bow)

	_check(
		"script_is_oot_bow_gd",
		bow.get_script() != null and bow.get_script().resource_path == "res://scripts/oot_bow.gd"
	)

	_check("second_hand_grab_enabled", bow.second_hand_grab == 2)

	_check("has_spawn_node", bow.get_node_or_null("Spawn") != null)

	var grip_count := 0
	var string_count := 0
	for child in bow.get_children():
		var child_script: Script = child.get_script()
		if child_script != null and child_script.resource_path.ends_with("grab_point_hand.gd"):
			if child.mode == 1:
				grip_count += 1
			elif child.mode == 2:
				string_count += 1
	_check("grab_points_configured", grip_count == 2 and string_count == 2)

	# At rest (no draw) the string-grab points must sit at the string/nock
	# meeting point — the arrow tail, beside the NockZone — not up at the riser.
	# Regression: NOCK_TAIL_OFFSET too small parked the grab point mid-shaft,
	# forcing the player to reach to the riser to pull the string.
	bow._process(0.0)
	var zone_z: float = bow.get_node("NockZone").position.z
	_check(
		"string_grab_rests_at_nock",
		abs(bow.get_node("StringGrabLeft").position.z - zone_z) < 0.05
		and abs(bow.get_node("StringGrabRight").position.z - zone_z) < 0.05
	)

	var handA := Node3D.new()
	var handB := Node3D.new()
	root.add_child(handA)
	root.add_child(handB)
	handA.global_position = Vector3.ZERO
	handB.global_position = Vector3(0, 0, 0.5)

	bow._on_bow_grabbed(bow, handA)
	bow._on_bow_grabbed(bow, handB)
	bow.load_arrow()
	bow._process(0.0)

	_check("draw_tracks_hands", abs(bow._draw - 1.0) < 0.0001)
	_check("nocked_arrow_visible_when_drawn", bow.get_node("NockedArrow").visible == true)

	var tree: AnimationTree = null
	for child in bow.get_children():
		if child is AnimationTree:
			tree = child
	_check("has_animation_tree", tree != null and tree.active)
	_check(
		"blend_tracks_draw",
		tree != null and abs(float(tree.get("parameters/blend/blend_amount")) - 1.0) < 0.0001
	)
	var player: AnimationPlayer = bow.get_node("Mesh").get_node_or_null("AnimationPlayer")
	_check(
		"mesh_has_pose_animations",
		player != null and player.has_animation("idle") and player.has_animation("Pull bow")
	)

	# Draw pulls the nocked arrow back along its OWN shaft axis from the
	# editor-authored rest pose. The rest transform in the tscn is the source
	# of truth (hand-placed in the editor); a canted shaft must slide through
	# the same riser contact point instead of drifting sideways.
	var nocked: Node3D = bow.get_node("NockedArrow")
	var rest: Transform3D = bow._nock_rest
	var back: Vector3 = -rest.basis.x.normalized()
	_check(
		"nocked_arrow_pulled_along_shaft",
		(nocked.position - (rest.origin + back * (bow.NOCK_PULL * bow._draw))).length() < 0.0001
	)
	var tail: Vector3 = nocked.position + back * bow.NOCK_TAIL_OFFSET
	_check(
		"string_hand_rides_arrow_tail",
		(bow.get_node("StringGrabLeft").position - tail).length() < 0.0001
		and (bow.get_node("StringGrabRight").position - tail).length() < 0.0001
	)
	# Regression check for "drifts off the riser": where the shaft line
	# crosses a fixed z-plane (the riser) must not move between rest and
	# full draw.
	var tip_dir: Vector3 = rest.basis.x.normalized()
	var plane_z := -0.08
	var rest_cross: Vector3 = rest.origin + tip_dir * ((plane_z - rest.origin.z) / tip_dir.z)
	var drawn_cross: Vector3 = nocked.position + tip_dir * ((plane_z - nocked.position.z) / tip_dir.z)
	_check("no_lateral_drift_at_riser", (drawn_cross - rest_cross).length() < 0.0001)

	bow._on_bow_released(bow, handB)
	var arrows: Array = get_nodes_in_group("arrows")
	_check(
		"fires_arrow_on_release",
		arrows.size() == 1 and abs(arrows[0].linear_velocity.length() - 30.0) < 0.001
	)

	var release_sound: Node = bow.get_node_or_null("ReleaseSound")
	_check(
		"release_sound_ready",
		release_sound is AudioStreamPlayer3D
		and release_sound.stream != null
		and release_sound.stream is AudioStreamMP3
	)

	bow._process(0.0)
	_check(
		"string_resets_after_fire",
		bow._draw == 0.0 and bow.get_node("NockedArrow").visible == false
	)
	_check(
		"blend_resets_after_fire",
		tree != null and abs(float(tree.get("parameters/blend/blend_amount"))) < 0.0001
	)

	handB.global_position = Vector3(0, 0, 0.05)
	bow._on_bow_grabbed(bow, handB)
	bow._process(0.0)
	bow._on_bow_released(bow, handB)
	_check(
		"no_fire_below_threshold",
		get_nodes_in_group("arrows").size() == 1
	)

	bow.global_position = Vector3(3, 3, 3)
	bow.reset_to_home()
	_check(
		"reset_restores_home",
		bow.global_transform.origin.distance_to(Vector3.ZERO) < 0.001
	)

	bow.queue_free()

	if _failures == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=%d" % _failures)
	quit()
