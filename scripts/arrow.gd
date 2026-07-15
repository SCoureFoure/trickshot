class_name Arrow
extends RigidBody3D

## Fired arrow projectile. Flies under engine gravity, orients nose-first
## along its velocity, sticks into the first surface hit (raycast between
## physics positions so speed cannot tunnel - this project has no CCD), and
## frees itself after STUCK_LIFETIME seconds stuck, MAX_FLIGHT_TIME seconds
## flying, or on falling out of the world.

const STUCK_LIFETIME := 10.0
const MAX_FLIGHT_TIME := 30.0
const MIN_ORIENT_SPEED := 0.5

var _flying := false
var _stuck := false
var _age := 0.0
var _last_position: Vector3


func _ready() -> void:
	add_to_group("arrows")
	_last_position = global_position


## Launches the arrow along its current -Z axis at the given speed in m/s.
func fire(speed: float) -> void:
	_flying = true
	_stuck = false
	_age = 0.0
	freeze = false
	linear_velocity = -global_transform.basis.z * speed
	_last_position = global_position


func _physics_process(delta: float) -> void:
	_age += delta
	if _stuck:
		if _age >= STUCK_LIFETIME:
			queue_free()
		return
	if not _flying:
		return
	if _age >= MAX_FLIGHT_TIME or global_position.y < -5.0:
		queue_free()
		return
	if linear_velocity.length() > MIN_ORIENT_SPEED:
		look_at(global_position + linear_velocity.normalized(), Vector3.UP)
	var query := PhysicsRayQueryParameters3D.create(_last_position, global_position)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		stick(hit.position)
	_last_position = global_position


## Freezes the arrow at the hit point so it appears stuck in the surface.
func stick(at: Vector3) -> void:
	_stuck = true
	_flying = false
	_age = 0.0
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_position = at
	$CollisionShape3D.set_deferred("disabled", true)
