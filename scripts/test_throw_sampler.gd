extends SceneTree

## Headless test suite for ThrowSampler. Run:
## godot --headless --path . --script res://scripts/test_throw_sampler.gd

var _failures := 0


func _check(name: String, cond: bool) -> void:
	if cond:
		print("PASS: " + name)
	else:
		_failures += 1
		print("FAIL: " + name)


func _initialize() -> void:
	_test_empty_returns_zero()
	_test_single_sample_returns_zero()
	_test_constant_velocity_recovered()
	_test_old_samples_dropped()
	_test_zero_time_span_returns_zero()
	_test_jitter_bounded()
	_test_clear_resets()
	if _failures == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=%d" % _failures)
	quit()


func _test_empty_returns_zero() -> void:
	var sampler := ThrowSampler.new()
	_check("empty_returns_zero", sampler.release_velocity() == Vector3.ZERO)


func _test_single_sample_returns_zero() -> void:
	var sampler := ThrowSampler.new()
	sampler.add_sample(0.0, Vector3.ONE)
	_check("single_sample_returns_zero", sampler.release_velocity() == Vector3.ZERO)


func _test_constant_velocity_recovered() -> void:
	var sampler := ThrowSampler.new()
	var v := Vector3(2, 0, 1)
	sampler.add_sample(0.0, v * 0.0)
	for i in range(1, 19):
		var t := i / 90.0
		sampler.add_sample(t, v * t)
	var vel := sampler.release_velocity()
	_check("constant_velocity_recovered", (vel - v).length() < 0.0001)


func _test_old_samples_dropped() -> void:
	var sampler := ThrowSampler.new()
	sampler.add_sample(0.0, Vector3.ZERO)
	sampler.add_sample(0.05, Vector3.ZERO)
	var v := Vector3(3, 0, 0)
	for i in range(9):
		var t := 1.0 + i / 90.0
		sampler.add_sample(t, v * (t - 1.0))
	var vel := sampler.release_velocity()
	_check("old_samples_dropped", (vel - v).length() < 0.01)


func _test_zero_time_span_returns_zero() -> void:
	var sampler := ThrowSampler.new()
	sampler.add_sample(0.5, Vector3.ZERO)
	sampler.add_sample(0.5, Vector3.ONE)
	_check("zero_time_span_returns_zero", sampler.release_velocity() == Vector3.ZERO)


func _test_jitter_bounded() -> void:
	var sampler := ThrowSampler.new()
	var v := Vector3(0, 2, 0)
	for i in range(18):
		var t := i / 90.0
		var noise := 0.002 if i % 2 == 0 else -0.002
		var pos := v * t + Vector3(noise, noise, noise)
		sampler.add_sample(t, pos)
	var vel := sampler.release_velocity()
	_check("jitter_bounded", (vel - v).length() < 0.1)


func _test_clear_resets() -> void:
	var sampler := ThrowSampler.new()
	sampler.add_sample(0.0, Vector3.ZERO)
	sampler.add_sample(0.05, Vector3.ONE)
	sampler.add_sample(0.08, Vector3(2, 2, 2))
	sampler.clear()
	_check("clear_resets", sampler.release_velocity() == Vector3.ZERO)
