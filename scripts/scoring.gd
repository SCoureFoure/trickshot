class_name Scoring
extends RefCounted

## Scoring system for target hits. Awards points by ring distance from target
## centre. Distances use inclusive boundaries: <= 0.15m = 25 points, <= 0.30m = 10,
## <= 0.45m = 5, > 0.45m = 0. Negative distances are invalid (return 0).

const RING_RADII: Array[float] = [0.15, 0.30, 0.45]
const RING_POINTS: Array[int] = [25, 10, 5]

var total: int = 0


static func points_for_ring_distance(d: float) -> int:
	if d < 0.0:
		return 0
	if d <= 0.15:
		return 25
	if d <= 0.30:
		return 10
	if d <= 0.45:
		return 5
	return 0


func register(points: int) -> int:
	if points > 0:
		total += points
	return total


func reset() -> void:
	total = 0
