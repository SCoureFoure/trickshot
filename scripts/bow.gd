@tool
class_name Bow
extends BowBase

## Two-hand bow. The first grabbing hand holds the grip (primary); the
## second grabs the string (secondary). Draw ratio comes from BowDraw
## applied to the distance between the two hands. Releasing the string at
## or above the fire threshold spawns an arrow at the Spawn node and fires
## it; below the threshold the arrow is quietly un-nocked.

const ARROW_SCENE := preload("res://scenes/arrow.tscn")

## How far the string/nocked arrow slide back at full draw, in meters.
@export var NOCK_PULL := -0.35

## Rest z of the string and nocked arrow in bow-local space (at the string,
## behind the grip).
@export var STRING_REST := -0.2

## Bow-local positions of the two limb tips where the string attaches.
@export var STRING_TIP_TOP := Vector3(0, 0.69, -0.21)
@export var STRING_TIP_BOTTOM := Vector3(0, -0.69, -0.21)

## The nocked-arrow mesh is origin-centered mid-shaft; its tail sits this far
## behind its origin (0.641 model units x 0.6 scale). Subtracting it puts the
## tail (fletching) exactly on the string instead of the shaft's midpoint.
@export var NOCK_TAIL_OFFSET := -0.385

## Height of the nock point (arrow + string vertex) in bow-local space -
## a little below the grip hand, which rides high on the riser.
@export var NOCK_HEIGHT := -0.04


func _update_draw_visual() -> void:
	var nock := Vector3(0, NOCK_HEIGHT, STRING_REST + NOCK_PULL * _draw)
	$NockedArrow.visible = _draw > 0.0 and _loaded
	$NockedArrow.position.y = NOCK_HEIGHT
	$NockedArrow.position.z = nock.z - NOCK_TAIL_OFFSET
	# The visible string hand snaps to these grab points, so riding them on
	# the nock makes the hand track the pull instead of floating at rest.
	$StringGrabLeft.position = nock
	$StringGrabRight.position = nock
	_stretch_between($StringTop, STRING_TIP_TOP, nock)
	_stretch_between($StringBottom, STRING_TIP_BOTTOM, nock)


## Positions and scales a unit-length Y-aligned segment mesh so it spans
## from `from` to `to` in bow-local space - the two segments meeting at the
## nock give the string its bend as the draw deepens.
func _stretch_between(segment: MeshInstance3D, from: Vector3, to: Vector3) -> void:
	var dir := to - from
	var seg_basis := Basis(Quaternion(Vector3.UP, dir.normalized())) \
		* Basis.from_scale(Vector3(1.0, dir.length(), 1.0))
	segment.transform = Transform3D(seg_basis, (from + to) * 0.5)


func _arrow_scene() -> PackedScene:
	return ARROW_SCENE
