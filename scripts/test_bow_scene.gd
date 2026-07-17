extends SceneTree

## Headless test suite for the Bow scene. Run:
## godot --headless --xr-mode off --path . --script res://scripts/test_bow_scene.gd

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
	var scene: PackedScene = load("res://scenes/bow.tscn")
	_check("scene_loads", scene != null)

	var bow = scene.instantiate()
	root.add_child(bow)

	_check(
		"script_is_bow_gd",
		bow.get_script() != null and bow.get_script().resource_path == "res://scripts/bow.gd"
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

	var nock := Vector3(0, bow.NOCK_HEIGHT, bow.STRING_REST + bow.NOCK_PULL * bow._draw)
	var string_top: MeshInstance3D = bow.get_node("StringTop")
	_check(
		"string_top_spans_tip_to_nock",
		abs(string_top.scale.y - (nock - bow.STRING_TIP_TOP).length()) < 0.001
		and string_top.position.distance_to((bow.STRING_TIP_TOP + nock) * 0.5) < 0.001
	)
	var string_bottom: MeshInstance3D = bow.get_node("StringBottom")
	_check(
		"string_bottom_spans_tip_to_nock",
		abs(string_bottom.scale.y - (nock - bow.STRING_TIP_BOTTOM).length()) < 0.001
		and string_bottom.position.distance_to((bow.STRING_TIP_BOTTOM + nock) * 0.5) < 0.001
	)

	_check(
		"nocked_arrow_tail_on_string",
		abs(bow.get_node("NockedArrow").position.z - (nock.z - bow.NOCK_TAIL_OFFSET)) < 0.0001
	)

	bow._on_bow_released(bow, handB)
	var arrows: Array = get_nodes_in_group("arrows")
	_check(
		"fires_arrow_on_release",
		arrows.size() == 1 and abs(arrows[0].linear_velocity.length() - 30.0) < 0.001
	)

	bow._process(0.0)
	_check(
		"string_resets_after_fire",
		bow._draw == 0.0 and bow.get_node("NockedArrow").visible == false
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

	var release_sound: Node = bow.get_node_or_null("ReleaseSound")
	_check(
		"release_sound_ready",
		release_sound is AudioStreamPlayer3D
		and release_sound.stream != null
		and release_sound.stream is AudioStreamMP3
	)

	bow.queue_free()

	if _failures == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=%d" % _failures)
	quit()
