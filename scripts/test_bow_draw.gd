extends SceneTree

## Headless test suite for BowDraw. Run:
## godot --headless --xr-mode off --path . --script res://scripts/test_bow_draw.gd

var _failures := 0


func _check(name: String, cond: bool) -> void:
	if cond:
		print("PASS: " + name)
	else:
		_failures += 1
		print("FAIL: " + name)


func _check_approx(name: String, a: float, b: float) -> void:
	if abs(a - b) < 0.0001:
		print("PASS: " + name)
	else:
		_failures += 1
		print("FAIL: " + name)


func _initialize() -> void:
	_test_bow_draw()
	if _failures == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=%d" % _failures)
	quit()


func _test_bow_draw() -> void:
	var bd = load("res://scripts/bow_draw.gd")

	_check("zero_distance_zero_ratio", bd.draw_ratio(0.0) == 0.0)
	_check("rest_distance_zero_ratio", bd.draw_ratio(0.15) == 0.0)
	_check_approx("half_draw", bd.draw_ratio(0.325), 0.5)
	_check_approx("full_draw", bd.draw_ratio(0.5), 1.0)
	_check_approx("over_draw_clamped", bd.draw_ratio(2.0), 1.0)
	_check("negative_distance_clamped", bd.draw_ratio(-0.3) == 0.0)

	_check("below_threshold_no_fire", bd.should_fire(0.19) == false)
	_check("at_threshold_fires", bd.should_fire(0.2) == true)

	_check_approx("no_fire_zero_speed", bd.arrow_speed(0.1), 0.0)
	_check_approx("threshold_speed", bd.arrow_speed(0.2), 10.0)
	_check_approx("full_draw_speed", bd.arrow_speed(1.0), 30.0)
	_check_approx("overdrawn_speed_clamped", bd.arrow_speed(1.5), 30.0)
