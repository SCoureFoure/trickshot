extends SceneTree

## Headless test suite for the KayKit Ranger character scene. Run:
## godot --headless --xr-mode off --path . --script res://scripts/test_character_scene.gd

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
	var scene: PackedScene = load("res://scenes/character.tscn")
	_check("scene_loads", scene != null)

	var ch = scene.instantiate()
	root.add_child(ch)

	_check(
		"script_is_character_gd",
		ch.get_script() != null
		and ch.get_script().resource_path == "res://scripts/character.gd"
	)

	var ap: AnimationPlayer = ch.get_node_or_null("AnimationPlayer")
	_check("has_animation_player", ap != null)

	_check(
		"anim_root_is_ranger",
		ap != null and ap.get_node_or_null(ap.root_node) == ch.get_node_or_null("Ranger")
	)

	var skel = ch.get_node_or_null("Ranger/Rig_Medium/Skeleton3D")
	_check("ranger_skeleton_present", skel is Skeleton3D)

	for lib in ["movement", "general", "ranged"]:
		_check("library_" + lib, ap != null and ap.has_animation_library(lib))

	for anim in ["general/Idle_A", "movement/Walking_A", "ranged/Ranged_Bow_Draw"]:
		_check("anim_" + anim.replace("/", "_"), ap != null and ap.has_animation(anim))

	_check(
		"default_idle_playing",
		ap != null and ap.is_playing() and ap.current_animation == "general/Idle_A"
	)

	# Loop policy: idles/walks/runs/aims loop, one-shots don't.
	var loop_cases := {
		"general/Idle_A": Animation.LOOP_LINEAR,
		"movement/Running_A": Animation.LOOP_LINEAR,
		"ranged/Ranged_Bow_Aiming_Idle": Animation.LOOP_LINEAR,
		"general/Throw": Animation.LOOP_NONE,
		"ranged/Ranged_Bow_Release": Animation.LOOP_NONE,
	}
	for anim_name in loop_cases:
		_check(
			"loop_" + anim_name.replace("/", "_"),
			ap != null
			and ap.has_animation(anim_name)
			and ap.get_animation(anim_name).loop_mode == loop_cases[anim_name]
		)

	# Animation must actually drive the skeleton (paths resolve through root_node).
	if skel is Skeleton3D and ap != null and ap.has_animation("movement/Running_A"):
		var hips: int = skel.find_bone("hips")
		var rest_rot: Quaternion = skel.get_bone_rest(hips).basis.get_rotation_quaternion()
		var rest_pos: Vector3 = skel.get_bone_rest(hips).origin
		ap.play("movement/Running_A")
		ap.advance(0.4)
		var moved: bool = (
			not skel.get_bone_pose_rotation(hips).is_equal_approx(rest_rot)
			or not skel.get_bone_pose_position(hips).is_equal_approx(rest_pos)
		)
		_check("skeleton_animates", moved)
	else:
		_check("skeleton_animates", false)

	if ch.has_method("play_anim"):
		ch.play_anim("ranged/Ranged_Bow_Draw")
		_check("play_anim_switches", ap.current_animation == "ranged/Ranged_Bow_Draw")
		ch.play_anim("nope/missing")
		_check("play_anim_ignores_unknown", ap.current_animation == "ranged/Ranged_Bow_Draw")
	else:
		_check("play_anim_switches", false)
		_check("play_anim_ignores_unknown", false)

	ch.queue_free()

	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)
	var placed = main.get_node_or_null("Character")
	_check(
		"character_placed_in_main",
		placed != null
		and placed.get_script() != null
		and placed.get_script().resource_path == "res://scripts/character.gd"
	)
	_check(
		"character_on_ground_downrange",
		placed != null
		and abs(placed.transform.origin.y) < 0.01
		and placed.transform.origin.z < 0.0
	)
	main.queue_free()

	if _failures == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=%d" % _failures)
	quit()
