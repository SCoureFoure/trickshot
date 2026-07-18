extends SceneTree

## Membrane for DebugWireGeometry.box_edges. Doer never sees this file.
## Corner convention: corner(i) = aabb.position + component-wise (size if bit set),
## bit0=x, bit1=y, bit2=z. 12 edges connect corners differing in exactly one bit.

var _failures := 0

const EDGES := [
	[0, 1], [0, 2], [0, 4], [1, 3], [1, 5], [2, 3],
	[2, 6], [3, 7], [4, 5], [4, 6], [5, 7], [6, 7],
]


func _corner(a: AABB, i: int) -> Vector3:
	return a.position + Vector3(
		a.size.x if (i & 1) else 0.0,
		a.size.y if (i & 2) else 0.0,
		a.size.z if (i & 4) else 0.0)


func _init() -> void:
	var a := AABB(Vector3(1, 2, 3), Vector3(2, 4, 6))
	var got: PackedVector3Array = DebugWireGeometry.box_edges(a)

	if got.size() != 24:
		print("FAIL: size got %d want 24" % got.size())
		_failures += 1
	else:
		var idx := 0
		for e in EDGES:
			var want_a := _corner(a, e[0])
			var want_b := _corner(a, e[1])
			if not got[idx].is_equal_approx(want_a):
				print("FAIL: edge %d v0 got %s want %s" % [idx / 2, got[idx], want_a])
				_failures += 1
			if not got[idx + 1].is_equal_approx(want_b):
				print("FAIL: edge %d v1 got %s want %s" % [idx / 2, got[idx + 1], want_b])
				_failures += 1
			idx += 2

	if _failures == 0:
		print("ALL_PASS")
	else:
		print("FAILURES=%d" % _failures)
	quit()
