extends SceneTree

## Headless test suite for RespawnPolicy. Run:
## godot --headless --path . --script res://scripts/test_respawn_policy.gd

var _failures := 0


func _check(name: String, cond: bool) -> void:
	if cond:
		print("PASS: " + name)
	else:
		_failures += 1
		print("FAIL: " + name)


func _initialize() -> void:
	_test_held_wins()
	_test_floor_rule_works()
	_test_floor_boundary_strict()
	_test_rack_ball_never_respawns()
	_test_rested_past_timeout()
	_test_timeout_boundary_strict()
	_test_speed_boundary_strict()
	_test_still_moving_not_recalled()
	_test_recently_thrown_not_yet_timeout()
	if _failures == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=%d" % _failures)
	quit()


func _test_held_wins() -> void:
	var result := RespawnPolicy.should_respawn(true, 10.0, -5.0, 0.0)
	_check("held_wins", result == false)


func _test_floor_rule_works() -> void:
	var result := RespawnPolicy.should_respawn(false, -1.0, -2.5, 0.0)
	_check("floor_rule_works", result == true)


func _test_floor_boundary_strict() -> void:
	var result := RespawnPolicy.should_respawn(false, -1.0, -2.0, 0.0)
	_check("floor_boundary_strict", result == false)


func _test_rack_ball_never_respawns() -> void:
	var result := RespawnPolicy.should_respawn(false, -1.0, 0.5, 0.0)
	_check("rack_ball_never_respawns", result == false)


func _test_rested_past_timeout() -> void:
	var result := RespawnPolicy.should_respawn(false, 6.0, 0.1, 0.05)
	_check("rested_past_timeout", result == true)


func _test_timeout_boundary_strict() -> void:
	var result := RespawnPolicy.should_respawn(false, 5.0, 0.1, 0.05)
	_check("timeout_boundary_strict", result == false)


func _test_speed_boundary_strict() -> void:
	var result := RespawnPolicy.should_respawn(false, 6.0, 0.1, 0.1)
	_check("speed_boundary_strict", result == false)


func _test_still_moving_not_recalled() -> void:
	var result := RespawnPolicy.should_respawn(false, 6.0, 0.1, 2.0)
	_check("still_moving_not_recalled", result == false)


func _test_recently_thrown_not_yet_timeout() -> void:
	var result := RespawnPolicy.should_respawn(false, 2.0, 0.1, 0.0)
	_check("recently_thrown_not_yet_timeout", result == false)
