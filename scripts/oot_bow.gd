@tool
extends BowBase

## Two-hand bow using the rigged OoT model. The first grabbing hand holds the
## grip (primary); the second grabs the string (secondary). Draw ratio comes
## from BowDraw applied to the distance between the two hands. The limb bend
## and string come from blending the imported "idle" (rest) and "Pull bow"
## (full draw) poses. The nocked arrow slides back along its own shaft axis
## from the editor-authored rest pose, preserving the riser contact point
## even if the shaft is canted. Releasing the string at or above the fire
## threshold spawns an arrow at the Spawn node and fires it; below the
## threshold the arrow is quietly un-nocked.

const ARROW_SCENE := preload("res://scenes/oot_arrow.tscn")

## How far the string/nocked arrow slide back at full draw, in meters. From
## the Pull_String bone at armature scale 0.652. Measured along the arrow's
## shaft axis.
const NOCK_PULL := 0.497

## The nocked-arrow mesh is origin-centered mid-shaft; its tail sits this far
## behind its origin (model units at scale 1). Subtracting it puts the tail
## (fletching) exactly on the string instead of the shaft's midpoint.
const NOCK_TAIL_OFFSET := 0.368

## Editor-authored rest transform of the nocked arrow — the source of truth
## for where the arrow sits on the riser. Draw slides the arrow back along
## this transform's own shaft axis (-basis.x), so a canted shaft keeps
## passing through the same riser contact point instead of drifting off it.
var _nock_rest := Transform3D()
var _blend_tree: AnimationTree = null


func _ready_runtime() -> void:
	_nock_rest = $NockedArrow.transform
	_setup_draw_blend()


## Builds an AnimationTree that blends the imported single-pose animations
## "idle" (rest) and "Pull bow" (full draw); _draw drives the blend amount.
func _setup_draw_blend() -> void:
	var player: AnimationPlayer = $Mesh.get_node_or_null("AnimationPlayer")
	if player == null:
		return
	var idle_node := AnimationNodeAnimation.new()
	idle_node.animation = "idle"
	var pull_node := AnimationNodeAnimation.new()
	pull_node.animation = "Pull bow"
	var blend := AnimationNodeBlend2.new()
	var tree_root := AnimationNodeBlendTree.new()
	tree_root.add_node("idle", idle_node)
	tree_root.add_node("pull", pull_node)
	tree_root.add_node("blend", blend)
	tree_root.connect_node("blend", 0, "idle")
	tree_root.connect_node("blend", 1, "pull")
	tree_root.connect_node("output", 0, "blend")
	_blend_tree = AnimationTree.new()
	add_child(_blend_tree)
	_blend_tree.anim_player = _blend_tree.get_path_to(player)
	_blend_tree.tree_root = tree_root
	_blend_tree.active = true


func _update_draw_visual() -> void:
	if _blend_tree != null:
		_blend_tree.set("parameters/blend/blend_amount", _draw)
	# The authored arrow basis maps model +X to the tip direction, so
	# -basis.x points from tip toward tail: the pull-back direction.
	var back := -_nock_rest.basis.x.normalized()
	var pull := NOCK_PULL * _draw
	$NockedArrow.visible = _draw > 0.0 and _loaded
	$NockedArrow.position = _nock_rest.origin + back * pull
	# The visible string hand snaps to these grab points, so riding them on
	# the arrow tail makes the hand track the pull instead of floating at rest.
	var nock := _nock_rest.origin + back * (NOCK_TAIL_OFFSET + pull)
	$StringGrabLeft.position = nock
	$StringGrabRight.position = nock


func _arrow_scene() -> PackedScene:
	return ARROW_SCENE


func _nock_offset() -> float:
	return NOCK_PULL * _draw
