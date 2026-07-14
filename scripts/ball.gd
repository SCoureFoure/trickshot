class_name Ball
extends XRToolsPickable

## Throwable ball. Wraps XRToolsPickable with ThrowSampler-based release
## velocity and RespawnPolicy-driven auto-respawn.

var home_transform: Transform3D
var sampler := ThrowSampler.new()
var _held := false
var _time := 0.0
var _since_release := -1.0  # -1 sentinel = never released; matches RespawnPolicy


func _ready() -> void:
	super._ready()
	home_transform = global_transform
	add_to_group("balls")


func _physics_process(delta: float) -> void:
	_time += delta
	if _held:
		sampler.add_sample(_time, global_position)
	else:
		if _since_release >= 0.0:
			_since_release += delta
	if RespawnPolicy.should_respawn(_held, _since_release, global_position.y, linear_velocity.length()):
		respawn()


func pick_up(by: Node3D) -> void:
	sampler.clear()
	_held = true
	super.pick_up(by)


func let_go(by: Node3D, p_linear_velocity: Vector3, p_angular_velocity: Vector3) -> void:
	_held = false
	_since_release = 0.0
	super.let_go(by, release_linear_velocity(p_linear_velocity), p_angular_velocity)
	sampler.clear()


## Returns the sampler's release velocity, unless it is exactly zero (no
## usable samples), in which case falls back to the pickup-provided velocity.
func release_linear_velocity(fallback: Vector3) -> Vector3:
	var sampled := sampler.release_velocity()
	if sampled == Vector3.ZERO:
		return fallback
	return sampled


func respawn() -> void:
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_transform = home_transform
	_since_release = -1.0
	sampler.clear()
