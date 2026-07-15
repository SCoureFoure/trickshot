class_name TreeDrag
extends Node3D

## Tree with a solid trunk and a drag-zone canopy: projectiles passing through
## the leaves are slowed by an Area3D damp override instead of bouncing off or
## flying through untouched. Shapes are built in _ready() scaled by tree_scale
## because CollisionShape3D nodes must not carry node scale.

@export var tree_scale: float = 6.0
@export var trunk_radius: float = 0.09
@export var trunk_base_y: float = -0.10
@export var trunk_top_y: float = 0.25
@export var canopy_radius: float = 0.32
@export var canopy_bottom_y: float = 0.10
@export var canopy_top_y: float = 1.10
@export var canopy_linear_damp: float = 1.2
@export var canopy_angular_damp: float = 1.2


func _ready() -> void:
	$Visual.scale = Vector3.ONE * tree_scale

	var trunk_shape := CylinderShape3D.new()
	trunk_shape.radius = trunk_radius * tree_scale
	trunk_shape.height = (trunk_top_y - trunk_base_y) * tree_scale
	$Trunk/CollisionShape3D.shape = trunk_shape
	$Trunk/CollisionShape3D.position = Vector3(0, (trunk_base_y + trunk_top_y) * 0.5 * tree_scale, 0)

	var canopy_shape := CylinderShape3D.new()
	canopy_shape.radius = canopy_radius * tree_scale
	canopy_shape.height = (canopy_top_y - canopy_bottom_y) * tree_scale
	$Canopy/CollisionShape3D.shape = canopy_shape
	$Canopy/CollisionShape3D.position = Vector3(0, (canopy_bottom_y + canopy_top_y) * 0.5 * tree_scale, 0)

	$Canopy.linear_damp_space_override = Area3D.SPACE_OVERRIDE_COMBINE
	$Canopy.linear_damp = canopy_linear_damp
	$Canopy.angular_damp_space_override = Area3D.SPACE_OVERRIDE_COMBINE
	$Canopy.angular_damp = canopy_angular_damp
