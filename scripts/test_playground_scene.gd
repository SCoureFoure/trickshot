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

	var left_pickup = main.get_node_or_null("XROrigin3D/LeftController/FunctionPickup")
	_check(
		"left_function_pickup",
		left_pickup != null
		and left_pickup.get_script() != null
		and left_pickup.get_script().resource_path.ends_with("function_pickup.gd")
	)

	var right_pickup = main.get_node_or_null("XROrigin3D/RightController/FunctionPickup")
	_check(
		"right_function_pickup",
		right_pickup != null
		and right_pickup.get_script() != null
		and right_pickup.get_script().resource_path.ends_with("function_pickup.gd")
	)

	var left_hand = main.get_node_or_null("XROrigin3D/LeftController/LeftHand")
	_check("has_left_hand", left_hand != null)

	var right_hand = main.get_node_or_null("XROrigin3D/RightController/RightHand")
	_check("has_right_hand", right_hand != null)

	_check("three_balls_in_group", get_nodes_in_group("balls").size() == 3)

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

	var b: Node3D = main.get_node("Ball1")
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
