extends SceneTree

## Headless test suite for bow load-state gating and dry-fire. Run:
## godot --headless --xr-mode off --path . --script res://scripts/test_bow_load.gd

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

	# --- Phase A: fresh empty bow (criteria 1-4) ---
	var bow1 = scene.instantiate()
	root.add_child(bow1)
	_check("starts_empty", bow1._loaded == false)

	var handA1 := Node3D.new()
	var handB1 := Node3D.new()
	root.add_child(handA1)
	root.add_child(handB1)
	handA1.global_position = Vector3.ZERO
	handB1.global_position = Vector3(0, 0, 0.5)

	bow1._on_bow_grabbed(bow1, handA1)
	bow1._on_bow_grabbed(bow1, handB1)
	bow1._process(0.0)
	_check(
		"empty_no_nock_visual",
		bow1.get_node("NockedArrow").visible == false and abs(bow1._draw - 1.0) < 0.0001
	)

	bow1._on_bow_released(bow1, handB1)
	_check("empty_release_dry_fires", get_nodes_in_group("arrows").size() == 0)

	var dry_fire_sound: Node = bow1.get_node_or_null("DryFireSound")
	var release_sound: Node = bow1.get_node_or_null("ReleaseSound")
	_check(
		"dry_fire_sound_wired",
		dry_fire_sound is AudioStreamPlayer3D
		and dry_fire_sound.stream != null
		and dry_fire_sound.stream is AudioStreamMP3
		and dry_fire_sound.stream != release_sound.stream
	)

	bow1.free()
	handA1.free()
	handB1.free()

	# --- Phase B: fresh bow loaded then fired (criteria 5-7) ---
	var bow2 = scene.instantiate()
	root.add_child(bow2)
	var handA2 := Node3D.new()
	var handB2 := Node3D.new()
	root.add_child(handA2)
	root.add_child(handB2)
	handA2.global_position = Vector3.ZERO
	handB2.global_position = Vector3(0, 0, 0.5)

	bow2._on_bow_grabbed(bow2, handA2)
	bow2._on_bow_grabbed(bow2, handB2)
	bow2.load_arrow()
	bow2._process(0.0)
	_check("load_makes_nock_visible", bow2.get_node("NockedArrow").visible == true)

	bow2._on_bow_released(bow2, handB2)
	var arrows: Array = get_nodes_in_group("arrows")
	_check(
		"loaded_release_fires_one",
		arrows.size() == 1 and abs(arrows[0].linear_velocity.length() - 30.0) < 0.001
	)
	_check("fire_consumes_load", bow2._loaded == false)

	for arrow in arrows:
		arrow.free()
	bow2.free()
	handA2.free()
	handB2.free()

	# --- Phase C: fresh bow, load then unload (criterion 8) ---
	var bow3 = scene.instantiate()
	root.add_child(bow3)
	bow3.load_arrow()
	bow3.unload_arrow()
	_check("unload_clears", bow3._loaded == false)
	bow3.free()

	# --- Phase D: fresh loaded bow, sub-threshold release (criterion 9) ---
	var bow4 = scene.instantiate()
	root.add_child(bow4)
	var handA4 := Node3D.new()
	var handB4 := Node3D.new()
	root.add_child(handA4)
	root.add_child(handB4)
	handA4.global_position = Vector3.ZERO
	handB4.global_position = Vector3(0, 0, 0.05)

	bow4._on_bow_grabbed(bow4, handA4)
	bow4._on_bow_grabbed(bow4, handB4)
	bow4.load_arrow()
	bow4._process(0.0)
	bow4._on_bow_released(bow4, handB4)
	_check(
		"subthreshold_keeps_load",
		get_nodes_in_group("arrows").size() == 0 and bow4._loaded == true
	)
	bow4.free()
	handA4.free()
	handB4.free()

	if _failures == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=%d" % _failures)
	quit()
