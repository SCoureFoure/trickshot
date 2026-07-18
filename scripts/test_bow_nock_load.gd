extends SceneTree

## Headless test for the single-arrow nock/fire loop on the OoT bow: nocking a
## loose pickable hides it and shows the bow's built-in arrow; firing returns the
## pickable and leaves exactly one projectile; un-nocking restores the pickable.
## Membrane for the bow_nock_toggle slice — the doer does not see this file.

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
	var pick_scene: PackedScene = load("res://scenes/arrow_pickable.tscn")
	_check("scenes_load", scene != null and pick_scene != null)

	# --- nock hides the pickable, shows the built-in arrow at rest ---
	var bow = scene.instantiate()
	root.add_child(bow)
	var pick = pick_scene.instantiate()
	root.add_child(pick)
	await process_frame
	_check("pickable_starts_visible", pick.visible == true)

	bow._on_nock_zone_picked_up(pick)
	_check("nock_loads", bow._loaded == true)
	_check("nock_hides_pickable", pick.visible == false)
	bow._process(0.0)
	_check("loaded_shows_nocked_arrow_at_rest", bow.get_node("NockedArrow").visible == true)

	# --- draw + fire: one projectile, pickable returned, no double arrow ---
	var hA := Node3D.new()
	var hB := Node3D.new()
	root.add_child(hA)
	root.add_child(hB)
	hA.global_position = Vector3.ZERO
	hB.global_position = Vector3(0, 0, 0.5)
	bow._on_bow_grabbed(bow, hA)
	bow._on_bow_grabbed(bow, hB)
	bow._process(0.0)
	bow._on_bow_released(bow, hB)
	var arrows: Array = get_nodes_in_group("arrows")
	_check("fire_spawns_one_projectile", arrows.size() == 1)
	_check("fire_returns_pickable_visible", pick.visible == true)
	_check("fire_clears_nocked_pickable", bow._nocked_pickable == null)
	_check("fire_consumes_load", bow._loaded == false)
	_check("fire_disables_nockzone_resnap", bow.get_node("NockZone").enabled == false)
	bow._process(0.0)
	_check("nocked_arrow_hidden_after_fire", bow.get_node("NockedArrow").visible == false)

	for a in arrows:
		a.free()
	bow.free()
	pick.free()
	hA.free()
	hB.free()

	# --- un-nock (arrow pulled back out) restores the pickable, no fire ---
	var bow2 = scene.instantiate()
	root.add_child(bow2)
	var pick2 = pick_scene.instantiate()
	root.add_child(pick2)
	await process_frame
	bow2._on_nock_zone_picked_up(pick2)
	_check("unnock_hidden", pick2.visible == false)
	bow2._on_nock_zone_dropped()
	_check("unnock_restores_visible", pick2.visible == true)
	_check("unnock_unloads", bow2._loaded == false)
	_check("unnock_clears_ref", bow2._nocked_pickable == null)
	bow2.free()
	pick2.free()

	if _failures == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=%d" % _failures)
	quit()
