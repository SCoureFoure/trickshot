extends SceneTree

## Headless test suite for the arrow nock snap zone. Run:
## godot --headless --xr-mode off --path . --script res://scripts/test_arrow_nock_zone.gd

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

	var pickable_scene: PackedScene = load("res://scenes/arrow_pickable.tscn")
	_check("pickable_scene_loads", pickable_scene != null)

	var pickable = pickable_scene.instantiate()
	root.add_child(pickable)

	_check(
		"pickable_is_grabbable",
		pickable.has_method("pick_up") and pickable.has_method("can_pick_up")
	)

	_check(
		"pickable_in_nockable_group",
		pickable.is_in_group("nockable") and not pickable.is_in_group("arrows")
	)

	var bow_scene: PackedScene = load("res://scenes/bow.tscn")
	var bow = bow_scene.instantiate()
	root.add_child(bow)

	var zone = bow.get_node("NockZone")
	_check("bow_has_nock_zone", zone.is_xr_class("XRToolsSnapZone"))
	_check("nock_zone_requires_nockable", zone.snap_require == "nockable")

	zone.has_picked_up.emit(null)
	_check("snap_loads_bow", bow._loaded == true)

	zone.has_dropped.emit()
	_check("drop_unloads_bow", bow._loaded == false)

	var oot_bow_scene: PackedScene = load("res://scenes/oot_bow.tscn")
	var oot_bow = oot_bow_scene.instantiate()
	root.add_child(oot_bow)

	var oot_zone = oot_bow.get_node("NockZone")
	oot_zone.has_picked_up.emit(null)
	_check("oot_bow_nock_zone_wired", oot_bow._loaded == true)

	pickable.queue_free()
	bow.queue_free()
	oot_bow.queue_free()

	if _failures == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=%d" % _failures)
	quit()
