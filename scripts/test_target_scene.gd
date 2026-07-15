extends SceneTree

## Headless test suite for Target. Run:
## godot --headless --path . --script res://scripts/test_target_scene.gd

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
	var scene: PackedScene = load("res://scenes/target.tscn")
	var target: Node3D = scene.instantiate()
	root.add_child(target)

	_check("script_path", target.get_script().resource_path == "res://scripts/target.gd")
	_check("has_target_hit_signal", target.has_signal("target_hit"))
	_check("bullseye_center", target.points_for_local_hit(Vector3(0, 0, 0)) == 25)
	_check("bullseye_diagonal", target.points_for_local_hit(Vector3(0.1, 0.1, 0)) == 25)
	_check("mid_ring", target.points_for_local_hit(Vector3(0.2, 0, 0)) == 10)
	_check("outer_ring", target.points_for_local_hit(Vector3(0, 0.4, 0)) == 5)
	_check("miss", target.points_for_local_hit(Vector3(0.5, 0, 0)) == 0)
	_check("z_ignored", target.points_for_local_hit(Vector3(0.2, 0, 0.9)) == 10)

	# arrow_body_scores: a body in the "arrows" group entering the face scores
	var arrow_body := Node3D.new()
	arrow_body.add_to_group("arrows")
	root.add_child(arrow_body)
	arrow_body.global_position = target.global_position + Vector3(0.1, 0.1, 0)
	var arrow_hits: Array = []
	var arrow_cb := func(points: int) -> void: arrow_hits.append(points)
	target.target_hit.connect(arrow_cb)
	target._on_face_body_entered(arrow_body)
	_check("arrow_body_scores", arrow_hits.size() == 1 and arrow_hits[0] > 0)
	target.target_hit.disconnect(arrow_cb)
	arrow_body.queue_free()

	# ungrouped_body_ignored: a body in neither group must not score
	var ungrouped_body := Node3D.new()
	root.add_child(ungrouped_body)
	ungrouped_body.global_position = target.global_position + Vector3(0.1, 0.1, 0)
	var ungrouped_hits: Array = []
	var ungrouped_cb := func(points: int) -> void: ungrouped_hits.append(points)
	target.target_hit.connect(ungrouped_cb)
	target._on_face_body_entered(ungrouped_body)
	_check("ungrouped_body_ignored", ungrouped_hits.is_empty())
	target.target_hit.disconnect(ungrouped_cb)
	ungrouped_body.queue_free()

	var face: Node = target.get_node("Face")
	_check("face_is_area3d", face is Area3D)
	var hit_sound: Node = target.get_node("HitSound")
	_check("hit_sound_is_audio_player", hit_sound is AudioStreamPlayer3D)
	_check("hit_sound_stream_built", hit_sound.stream != null)

	var ring_outer: Node = target.get_node("Rings/RingOuter")
	var ring_mid: Node = target.get_node("Rings/RingMid")
	var ring_center: Node = target.get_node("Rings/RingCenter")
	_check("ring_outer_is_mesh_instance", ring_outer is MeshInstance3D)
	_check("ring_mid_is_mesh_instance", ring_mid is MeshInstance3D)
	_check("ring_center_is_mesh_instance", ring_center is MeshInstance3D)

	target.free()

	if _failures == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=%d" % _failures)
	quit()
