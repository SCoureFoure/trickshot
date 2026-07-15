class_name Arrow
extends RigidBody3D

## Fired arrow projectile. Flies under engine gravity, orients nose-first
## along its velocity, sticks into the first surface hit (raycast between
## successive tip positions so speed cannot tunnel - this project has no CCD),
## and frees itself after STUCK_LIFETIME seconds stuck, MAX_FLIGHT_TIME
## seconds flying, or on falling out of the world.

const STUCK_LIFETIME := 10.0
const MAX_FLIGHT_TIME := 30.0
const MIN_ORIENT_SPEED := 0.5

## Nose length: how far the arrow tip sits ahead of the body origin along
## local -Z. Must match the collision capsule's front extent — the stick
## raycast runs tip-to-tip so a long nose (OoT: 0.55) still crosses the
## surface that stopped the capsule.
@export var tip_length := 0.2

## How deep the nose buries into the surface on stick.
const STICK_PENETRATION := 0.2

var _flying := false
var _stuck := false
var _age := 0.0
var _last_tip: Vector3


func _ready() -> void:
	add_to_group("arrows")
	_last_tip = _tip()


## Launches the arrow along its current -Z axis at the given speed in m/s.
func fire(speed: float) -> void:
	_flying = true
	_stuck = false
	_age = 0.0
	freeze = false
	linear_velocity = -global_transform.basis.z * speed
	_last_tip = _tip()


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
	var tip := _tip()
	var query := PhysicsRayQueryParameters3D.create(_last_tip, tip)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		stick(hit.position)
	_last_tip = tip


## Freezes the arrow at the hit point so it appears stuck in the surface.
func stick(at: Vector3) -> void:
	_stuck = true
	_flying = false
	_age = 0.0
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_position = at + global_transform.basis.z * (tip_length - STICK_PENETRATION)
	$CollisionShape3D.set_deferred("disabled", true)


func _tip() -> Vector3:
	return global_position - global_transform.basis.z * tip_length
