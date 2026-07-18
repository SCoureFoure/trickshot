extends SceneTree

## Membrane for DebugConfig.parse / should_track. Doer never sees this file.

func _fail(msg: String) -> void:
	print("FAIL: ", msg)
	_failures += 1

var _failures := 0


func _eq_cfg(got: Dictionary, enabled: bool, all: bool, ids: Array, label: String) -> void:
	if got.get("enabled") != enabled:
		_fail("%s enabled: got %s want %s" % [label, got.get("enabled"), enabled])
	if got.get("all") != all:
		_fail("%s all: got %s want %s" % [label, got.get("all"), all])
	var got_ids := Array(got.get("ids", []))
	if got_ids != ids:
		_fail("%s ids: got %s want %s" % [label, got_ids, ids])


func _init() -> void:
	_eq_cfg(DebugConfig.parse(""), false, false, [], "empty")
	_eq_cfg(DebugConfig.parse("false"), false, false, [], "false")
	_eq_cfg(DebugConfig.parse("FALSE"), false, false, [], "FALSE")
	_eq_cfg(DebugConfig.parse("  false  "), false, false, [], "padded-false")
	_eq_cfg(DebugConfig.parse("0"), false, false, [], "zero")
	_eq_cfg(DebugConfig.parse("true"), true, true, [], "true")
	_eq_cfg(DebugConfig.parse("TRUE"), true, true, [], "TRUE")
	_eq_cfg(DebugConfig.parse("1"), true, true, [], "one")
	_eq_cfg(DebugConfig.parse("oot-bow,arrow"), true, false, ["oot-bow", "arrow"], "list2")
	_eq_cfg(DebugConfig.parse(" oot-bow , arrow "), true, false, ["oot-bow", "arrow"], "list2-pad")
	_eq_cfg(DebugConfig.parse("oot-bow"), true, false, ["oot-bow"], "list1")
	# Must NOT treat "trueish" as the all-keyword — only exact true/1.
	_eq_cfg(DebugConfig.parse("trueish"), true, false, ["trueish"], "trueish")
	# Empty segments dropped.
	_eq_cfg(DebugConfig.parse("a,,b,"), true, false, ["a", "b"], "empty-segs")

	if DebugConfig.should_track(DebugConfig.parse("true"), "anything") != true:
		_fail("should_track all")
	if DebugConfig.should_track(DebugConfig.parse("false"), "x") != false:
		_fail("should_track disabled")
	if DebugConfig.should_track(DebugConfig.parse("a,b"), "b") != true:
		_fail("should_track hit")
	if DebugConfig.should_track(DebugConfig.parse("a,b"), "c") != false:
		_fail("should_track miss")

	if _failures == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=%d" % _failures)
	quit()
