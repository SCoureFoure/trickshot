extends SceneTree

## Headless test suite for bow hand-role re-grab guarding. Run:
## godot --headless --xr-mode off --path . --script res://scripts/test_bow_hand_roles.gd

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
	var bow = scene.instantiate()
	root.add_child(bow)

	var handA := Node3D.new()
	var handB := Node3D.new()
	root.add_child(handA)
	root.add_child(handB)
	handA.global_position = Vector3.ZERO
	handB.global_position = Vector3(0, 0, 0.5)

	bow._on_bow_grabbed(bow, handA)
	_check("first_grab_sets_grip", bow._grip_hand == handA and bow._string_hand == null)

	bow._on_bow_grabbed(bow, handA)
	_check("duplicate_grip_grab_ignored", bow._string_hand == null)

	bow._process(0.0)
	_check("draw_stays_zero_on_duplicate", bow._draw == 0.0)

	bow._on_bow_grabbed(bow, handB)
	bow._process(0.0)
	_check(
		"second_hand_sets_string",
		bow._string_hand == handB and abs(bow._draw - 1.0) < 0.0001
	)

	bow._on_bow_grabbed(bow, handB)
	_check(
		"duplicate_string_grab_ignored",
		bow._grip_hand == handA and bow._string_hand == handB
	)

	bow.queue_free()

	if _failures == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=%d" % _failures)
	quit()
