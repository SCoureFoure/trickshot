extends SceneTree

## Membrane for DebugHudFormat.render. Doer never sees this file.

var _failures := 0


func _check(got: String, want: String, label: String) -> void:
	if got != want:
		print("FAIL: %s\n--- got ---\n%s\n--- want ---\n%s" % [label, got, want])
		_failures += 1


func _init() -> void:
	var state := {
		"frame": 42,
		"time": "14:57:49",
		"camera": {"pos": Vector3(0.35, 1.6, 0.8), "dir": Vector3(0, 0, -1)},
		"bow": {"draw": 0.75, "loaded": true, "nock": 0.37},
		"tracked": [
			{"id": "oot-bow-nocked", "pos": Vector3(1, 2, 3), "rot_deg": Vector3(0, 90, 0)},
			{"id": "arrow", "pos": Vector3(-1.5, 0.25, 4), "rot_deg": Vector3(10, 0, -5)},
		],
	}
	var want := "\n".join([
		"[f42 14:57:49]",
		"CAM pos(0.35, 1.60, 0.80) dir(0.00, 0.00, -1.00)",
		"BOW draw=0.75 loaded=true nock=0.37",
		"oot-bow-nocked pos(1.00, 2.00, 3.00) rot(0.00, 90.00, 0.00)",
		"arrow pos(-1.50, 0.25, 4.00) rot(10.00, 0.00, -5.00)",
	])
	_check(DebugHudFormat.render(state), want, "full")

	var state2 := {
		"frame": 1,
		"time": "00:00:00",
		"camera": {"pos": Vector3.ZERO, "dir": Vector3(0, 0, -1)},
		"tracked": [],
	}
	var want2 := "\n".join([
		"[f1 00:00:00]",
		"CAM pos(0.00, 0.00, 0.00) dir(0.00, 0.00, -1.00)",
	])
	_check(DebugHudFormat.render(state2), want2, "no-bow-no-tracked")

	# loaded=false must render literally, bow line still present.
	var state3 := {
		"frame": 7,
		"time": "01:02:03",
		"camera": {"pos": Vector3.ZERO, "dir": Vector3(0, 0, -1)},
		"bow": {"draw": 0.0, "loaded": false, "nock": 0.0},
		"tracked": [],
	}
	var want3 := "\n".join([
		"[f7 01:02:03]",
		"CAM pos(0.00, 0.00, 0.00) dir(0.00, 0.00, -1.00)",
		"BOW draw=0.00 loaded=false nock=0.00",
	])
	_check(DebugHudFormat.render(state3), want3, "loaded-false")

	if _failures == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=%d" % _failures)
	quit()
