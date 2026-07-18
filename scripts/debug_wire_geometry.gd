class_name DebugWireGeometry
extends RefCounted

## Turn an AABB into vertex pairs for a wireframe box. Each edge is a pair of
## vertices, ready to feed an ImmediateMesh in Mesh.PRIMITIVE_LINES mode.

static func box_edges(aabb: AABB) -> PackedVector3Array:
	var result := PackedVector3Array()

	# The 12 cube edges as pairs of corner indices
	var edges := [
		[0, 1], [0, 2], [0, 4], [1, 3], [1, 5], [2, 3],
		[2, 6], [3, 7], [4, 5], [4, 6], [5, 7], [6, 7],
	]

	# For each edge, append the two corner vertices
	for edge in edges:
		var a: int = edge[0]
		var b: int = edge[1]
		result.append(_corner(aabb, a))
		result.append(_corner(aabb, b))

	return result


static func _corner(aabb: AABB, i: int) -> Vector3:
	## Calculate corner position from index using bit flags.
	## bit0=x, bit1=y, bit2=z
	return aabb.position + Vector3(
		aabb.size.x if (i & 1) else 0.0,
		aabb.size.y if (i & 2) else 0.0,
		aabb.size.z if (i & 4) else 0.0)
