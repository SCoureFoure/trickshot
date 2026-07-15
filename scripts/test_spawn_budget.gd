extends SceneTree

## Headless test suite for SpawnBudget. Run:
## godot --headless --xr-mode off --path . --script res://scripts/test_spawn_budget.gd

var _failures := 0


func _check(name: String, cond: bool) -> void:
	if cond:
		print("PASS: " + name)
	else:
		_failures += 1
		print("FAIL: " + name)


func _initialize() -> void:
	_test_overflow()
	if _failures == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=%d" % _failures)
	quit()


func _test_overflow() -> void:
	var sb = load("res://scripts/spawn_budget.gd")
	_check("under_cap_zero", sb.overflow(3, 10) == 0)
	_check("at_cap_zero", sb.overflow(10, 10) == 0)
	_check("one_over_cap", sb.overflow(11, 10) == 1)
	_check("three_over_cap", sb.overflow(13, 10) == 3)
	_check("zero_count_zero", sb.overflow(0, 10) == 0)
	_check("zero_cap_frees_all", sb.overflow(4, 0) == 4)
	_check("negative_cap_as_zero", sb.overflow(2, -5) == 2)
