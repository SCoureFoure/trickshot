@tool
class_name BowBase
extends XRToolsPickable

## Shared two-hand bow logic. The first grabbing hand holds the grip
## (primary); the second grabs the string (secondary). Draw ratio comes from
## BowDraw applied to the distance between the two hands. Releasing the string
## at or above the fire threshold fires; below the threshold the arrow is
## quietly un-nocked. Subclasses supply the draw VISUAL (procedural string vs
## rigged-pose blend) and the arrow scene they fire.

var home_transform: Transform3D
var _grip_hand: Node3D = null
var _string_hand: Node3D = null
var _draw := 0.0

## True when an arrow has been loaded into the nock (via load_arrow). An empty
## bow shows no nocked arrow and dry-fires instead of firing.
var _loaded := false


func _ready() -> void:
	super._ready()
	home_transform = global_transform
	grabbed.connect(_on_bow_grabbed)
	released.connect(_on_bow_released)
	var nock_zone := get_node_or_null("NockZone")
	if nock_zone != null:
		nock_zone.has_picked_up.connect(_on_nock_zone_picked_up)
		nock_zone.has_dropped.connect(_on_nock_zone_dropped)
	if not Engine.is_editor_hint():
		_ready_runtime()


## Overridable: subclass runtime-only setup (blend tree, cached rest pose).
## Base does nothing.
func _ready_runtime() -> void:
	pass


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _grip_hand != null and _string_hand != null:
		_draw = BowDraw.draw_ratio(
			_grip_hand.global_position.distance_to(_string_hand.global_position)
		)
	else:
		_draw = 0.0
	_update_draw_visual()


## Overridable: subclass renders the current `_draw` state. Base does nothing.
func _update_draw_visual() -> void:
	pass


func _on_bow_grabbed(_pickable, by: Node3D) -> void:
	# A hand already holding a role must not be re-assigned: a duplicate
	# grabbed signal from the grip hand would otherwise land it in the string
	# slot too, collapsing the two-hand distance (and the draw) to zero.
	if by == _grip_hand or by == _string_hand:
		return
	if _grip_hand == null:
		_grip_hand = by
	else:
		_string_hand = by


func _on_bow_released(_pickable, by: Node3D) -> void:
	if by == _string_hand:
		if BowDraw.should_fire(_draw):
			if _loaded:
				_fire(_draw)
				_loaded = false
			else:
				_dry_fire()
		_string_hand = null
	elif by == _grip_hand:
		_grip_hand = null
		_string_hand = null


## Puts an arrow in the bow: the next full-draw release fires a real arrow.
func load_arrow() -> void:
	_loaded = true


## Removes the arrow from the bow without firing.
func unload_arrow() -> void:
	_loaded = false


func _on_nock_zone_picked_up(_what) -> void:
	load_arrow()


func _on_nock_zone_dropped() -> void:
	unload_arrow()


## A full-draw release with no arrow loaded: distinct sound, no projectile.
func _dry_fire() -> void:
	$DryFireSound.play()


func _fire(ratio: float) -> void:
	var arrow := _arrow_scene().instantiate()
	get_parent().add_child(arrow)
	arrow.global_transform = $Spawn.global_transform
	arrow.fire(BowDraw.arrow_speed(ratio))
	$ReleaseSound.play()


## Overridable: the PackedScene this bow fires. Base returns null.
func _arrow_scene() -> PackedScene:
	return null


## Returns the bow to where it started (used by the scene reset button).
func reset_to_home() -> void:
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_transform = home_transform
