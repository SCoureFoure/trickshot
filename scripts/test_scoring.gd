extends SceneTree

## Headless test suite for Scoring. Run:
## godot --headless --path . --script res://scripts/test_scoring.gd

var _failures := 0


func _check(name: String, cond: bool) -> void:
	if cond:
		print("PASS: " + name)
	else:
		_failures += 1
		print("FAIL: " + name)


func _initialize() -> void:
	_test_points_for_ring_distance()
	_test_register_instance()
	if _failures == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=%d" % _failures)
	quit()


func _test_points_for_ring_distance() -> void:
	_check("points_for_ring_distance(0.0) == 25", Scoring.points_for_ring_distance(0.0) == 25)
	_check("points_for_ring_distance(0.15) == 25", Scoring.points_for_ring_distance(0.15) == 25)
	_check("points_for_ring_distance(0.1500001) == 10", Scoring.points_for_ring_distance(0.1500001) == 10)
	_check("points_for_ring_distance(0.30) == 10", Scoring.points_for_ring_distance(0.30) == 10)
	_check("points_for_ring_distance(0.45) == 5", Scoring.points_for_ring_distance(0.45) == 5)
	_check("points_for_ring_distance(0.46) == 0", Scoring.points_for_ring_distance(0.46) == 0)
	_check("points_for_ring_distance(-0.01) == 0", Scoring.points_for_ring_distance(-0.01) == 0)


func _test_register_instance() -> void:
	var scoring := Scoring.new()
	_check("fresh instance: total == 0", scoring.total == 0)
	var r1 := scoring.register(25)
	_check("register(25) returns 25", r1 == 25)
	_check("after register(25): total == 25", scoring.total == 25)
	var r2 := scoring.register(5)
	_check("register(5) returns 30", r2 == 30)
	_check("after register(5): total == 30", scoring.total == 30)
	var r3 := scoring.register(0)
	_check("register(0) returns 30", r3 == 30)
	_check("after register(0): total == 30", scoring.total == 30)
	var r4 := scoring.register(-10)
	_check("register(-10) returns 30", r4 == 30)
	_check("after register(-10): total == 30", scoring.total == 30)
	scoring.reset()
	_check("after reset(): total == 0", scoring.total == 0)
