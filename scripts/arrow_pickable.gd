@tool
extends XRToolsPickable

## A grabbable arrow that falls under gravity and plants itself: it freezes when
## its tip strikes a surface (raycast between successive tip positions, matching
## the no-CCD stick used by the fired projectile arrow). While held — by a hand
## or a snap zone — it never sticks; grabbing a planted arrow un-sticks it via
## the pickable's own pick-up (which clears `freeze`).

## How far the tip sits ahead of the body origin along local -Z (the arrow's
## forward/tip direction, same convention as arrow.gd). Must be about the
## capsule's front half-extent.
@export var tip_length := 0.25

var _stuck := false
var _last_tip: Vector3
var _home: Transform3D


func _ready() -> void:
	super._ready()
	add_to_group("nockable")
	_home = global_transform
	_last_tip = _tip()


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# Held (hand or snap zone): never stick; keep the tip reference current so a
	# release starts a fresh stick segment.
	if is_picked_up():
		_stuck = false
		_last_tip = _tip()
		return
	if _stuck or freeze:
		_last_tip = _tip()
		return
	var tip := _tip()
	var query := PhysicsRayQueryParameters3D.create(_last_tip, tip)
	query.exclude = _stick_exclusions()
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		_stick()
	_last_tip = tip


## Every loose arrow (this one + all other "nockable" bodies) is excluded from
## the stick ray, so a cluster of arrows never freezes onto each other — only a
## real surface stops one.
func _stick_exclusions() -> Array[RID]:
	var ex: Array[RID] = [get_rid()]
	for n in get_tree().get_nodes_in_group("nockable"):
		if n != self and n is CollisionObject3D:
			ex.append(n.get_rid())
	return ex


## Freezes the arrow where it is, so it reads as planted in the surface.
func _stick() -> void:
	_stuck = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true


func _tip() -> Vector3:
	return global_position - global_transform.basis.z * tip_length


## Returns the arrow to its scene-start pose and lets it fall again (used by the
## scene reset button).
func reset_to_home() -> void:
	_stuck = false
	freeze = false
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_transform = _home
	_last_tip = _tip()
