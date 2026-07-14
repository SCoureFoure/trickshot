class_name ThrowSampler
extends RefCounted

## Ring buffer of timestamped controller positions. Release velocity is the
## average velocity across the sample window, which smooths tracking jitter
## at the moment of release.

const WINDOW := 0.1  # seconds of history considered at release
const MAX_SAMPLES := 16

var _times: Array[float] = []
var _positions: Array[Vector3] = []


func add_sample(t: float, pos: Vector3) -> void:
	_times.append(t)
	_positions.append(pos)
	# Drop samples older than the window relative to the newest sample.
	var cutoff := t - WINDOW
	while _times.size() > 1 and _times[0] < cutoff:
		_times.pop_front()
		_positions.pop_front()
	while _times.size() > MAX_SAMPLES:
		_times.pop_front()
		_positions.pop_front()


func release_velocity() -> Vector3:
	if _times.size() < 2:
		return Vector3.ZERO
	var dt := _times[-1] - _times[0]
	if dt <= 0.0:
		return Vector3.ZERO
	return (_positions[-1] - _positions[0]) / dt


func clear() -> void:
	_times.clear()
	_positions.clear()
