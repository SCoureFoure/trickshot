extends SceneTree

## Headless test suite for the loose arrow pickable scene. Run:
## godot --headless --xr-mode off --path . --script res://scripts/test_arrow_pickable_scene.gd

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

	var scene: PackedScene = load("res://scenes/arrow_pickable.tscn")
	_check("scene_loads", scene != null)

	var arrow = scene.instantiate()
	root.add_child(arrow)

	_check(
		"script_is_arrow_pickable",
		arrow.get_script() != null and arrow.get_script().resource_path == "res://scripts/arrow_pickable.gd"
	)
	_check(
		"is_pickable",
		arrow.has_method("pick_up") and arrow.has_method("can_pick_up")
	)
	_check(
		"in_nockable_group",
		arrow.is_in_group("nockable") and not arrow.is_in_group("arrows")
	)
	arrow.queue_free()

	# Thick floor, top surface at ~y=0.
	var floor := StaticBody3D.new()
	var floor_col := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(10, 1, 10)
	floor_col.shape = floor_box
	floor.add_child(floor_col)
	floor.position = Vector3(0, -0.5, 0)
	root.add_child(floor)

	# Tip-down orientation: local -Z (the tip) points at world -Y.
	var tip_down_basis := Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0))

	# plants_on_floor: dropped tip-down above the floor, freezes near it.
	var planted = scene.instantiate()
	planted.transform = Transform3D(tip_down_basis, Vector3(0, 1.5, 0))
	planted.freeze = false
	root.add_child(planted)
	for i in range(180):
		await physics_frame
	_check("plants_on_floor_freezes", planted.freeze == true)
	# Rests with tip buried in the floor and origin ~tip_length (OoT: 0.55) above
	# it, plus a frame of overshoot — so the upper bound tracks the OoT arrow.
	_check(
		"plants_on_floor_rests_near_floor",
		planted.global_position.y >= -0.1 and planted.global_position.y <= 0.7
	)

	# no_floor_keeps_falling: same tip-down orientation, nothing below it.
	var falling = scene.instantiate()
	falling.transform = Transform3D(tip_down_basis, Vector3(50, 1.5, 50))
	falling.freeze = false
	root.add_child(falling)
	for i in range(60):
		await physics_frame
	_check("no_floor_not_frozen", falling.freeze == false)
	_check("no_floor_has_fallen", falling.global_position.y < 1.5)

	# clustered_arrows_dont_stick_each_other: two arrows close together must
	# fall to the floor, not freeze onto each other on the first frame.
	var a1 = scene.instantiate()
	a1.transform = Transform3D(tip_down_basis, Vector3(0, 1.5, 0))
	a1.freeze = false
	root.add_child(a1)
	var a2 = scene.instantiate()
	a2.transform = Transform3D(tip_down_basis, Vector3(0.03, 1.5, 0))
	a2.freeze = false
	root.add_child(a2)
	for i in range(180):
		await physics_frame
	_check(
		"clustered_arrows_dont_stick_each_other",
		a1.global_position.y < 1.0 and a2.global_position.y < 1.0
	)
	a1.queue_free()
	a2.queue_free()

	planted.queue_free()
	falling.queue_free()
	floor.queue_free()

	if _failures == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=%d" % _failures)
	quit()
