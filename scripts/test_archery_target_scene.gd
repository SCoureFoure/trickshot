extends SceneTree

## Headless test suite for Archery Target. Run:
## godot --headless --xr-mode off --path . --script res://scripts/test_archery_target_scene.gd

const BULL := Vector3(-0.005, 0.613, -0.171)

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
	var scene: PackedScene = load("res://scenes/archery_target.tscn")
	_check("scene_loads", scene != null)

	var target: Node3D = scene.instantiate()
	root.add_child(target)

	_check("script_is_target_gd", target.get_script().resource_path == "res://scripts/target.gd")
	_check("has_kaykit_mesh", target.get_node_or_null("Mesh") != null)
	_check("has_backing_body", target.get_node_or_null("Backing") is StaticBody3D)
	var face: Node = target.get_node_or_null("Face")
	_check("face_area_monitoring", face is Area3D and face.monitoring == true)

	# Backing must cover the whole visible KayKit target (1.56 w x 1.96 h at
	# scale 6.5), be thick enough that fast balls can't tunnel (no CCD), and
	# present its front plane at z ~= 0 so arrows cross the scoring Face area
	# (z 0..0.08) before contact.
	var backing: Node3D = target.get_node("Backing")
	var backing_shape: Shape3D = target.get_node("Backing/CollisionShape3D").shape
	_check(
		"backing_covers_visual",
		backing_shape is BoxShape3D
		and backing_shape.size.x >= 1.5
		and backing_shape.size.y >= 1.8
		and backing_shape.size.z >= 0.4
	)
	var backing_front := 0.0
	if backing_shape is BoxShape3D:
		var shape_node: Node3D = target.get_node("Backing/CollisionShape3D")
		backing_front = backing.position.z + shape_node.position.z + backing_shape.size.z / 2.0
	_check("backing_front_at_face", abs(backing_front) <= 0.05)
	var hit_sound: Node = target.get_node("HitSound")
	_check(
		"hit_sound_ready",
		hit_sound is AudioStreamPlayer3D
		and hit_sound.stream != null
		and hit_sound.stream is AudioStreamMP3
	)

	_check("bullseye_scores_25", target.points_for_local_hit(BULL) == 25)
	_check("mid_ring_scores_10", target.points_for_local_hit(BULL + Vector3(0.2, 0, 0)) == 10)
	_check("outer_ring_scores_5", target.points_for_local_hit(BULL + Vector3(0, 0.4, 0)) == 5)
	_check("miss_scores_0", target.points_for_local_hit(BULL + Vector3(0.5, 0, 0)) == 0)
	_check("origin_is_not_bull", target.points_for_local_hit(Vector3.ZERO) == 0)
	_check(
		"bull_center_exported",
		abs(target.bull_center.x - BULL.x) < 0.001
		and abs(target.bull_center.y - BULL.y) < 0.001
		and abs(target.bull_center.z - BULL.z) < 0.001
	)

	var scored := []
	target.target_hit.connect(func(points): scored.append(points))
	var arrow_body := RigidBody3D.new()
	arrow_body.add_to_group("arrows")
	root.add_child(arrow_body)
	arrow_body.global_position = target.to_global(BULL)
	target._on_face_body_entered(arrow_body)
	_check("arrow_hit_scores_bullseye", scored == [25])
	target._on_face_body_entered(arrow_body)
	_check("cooldown_blocks_double_hit", scored == [25])
	var stranger := RigidBody3D.new()
	root.add_child(stranger)
	stranger.global_position = target.to_global(BULL)
	target._on_face_body_entered(stranger)
	_check("non_arrow_ignored", scored == [25])

	var arrow_scene: PackedScene = load("res://scenes/oot_arrow.tscn")
	var real_arrow: RigidBody3D = arrow_scene.instantiate()
	root.add_child(real_arrow)
	real_arrow.global_position = target.to_global(BULL) + Vector3(0, 0, 1)
	real_arrow.stick(target.to_global(BULL), target.get_node("Backing/CollisionShape3D"))
	_check("stuck_arrow_scores_bullseye", scored == [25, 25])
	real_arrow.stick(target.to_global(BULL), target.get_node("Backing/CollisionShape3D"))
	_check("stuck_arrow_cooldown_blocks_repeat", scored == [25, 25])
	var free_arrow: RigidBody3D = arrow_scene.instantiate()
	root.add_child(free_arrow)
	free_arrow.stick(Vector3(50, 0, 0), null)
	_check("stick_without_collider_safe", scored == [25, 25])
	real_arrow.queue_free()
	free_arrow.queue_free()

	target.free()

	if _failures == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=%d" % _failures)
	quit()
