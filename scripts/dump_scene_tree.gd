extends SceneTree

## Dev tool: dump the node tree of any scene (gltf/glb/tscn), including
## collision shape classes. Used to verify import-generated physics without
## opening the editor. Run:
## godot --headless --xr-mode off --path . --script res://scripts/dump_scene_tree.gd -- res://assets/kaykit_hex/barrel.gltf
##
## NOTE: the Windows Godot exe detaches from the console; redirect stdout to a
## file to see output (see .claude/skills/import-asset/SKILL.md).

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print("USAGE: -- <res://path/to/scene>")
		quit(1)
		return
	var ps: PackedScene = load(args[0])
	if ps == null:
		print("LOAD_FAIL: " + args[0])
		quit(1)
		return
	var root := ps.instantiate()
	_dump(root, 0)
	root.free()
	quit(0)


func _dump(node: Node, depth: int) -> void:
	var extra := ""
	if node is CollisionShape3D:
		var shp: Shape3D = (node as CollisionShape3D).shape
		extra = "  shape=" + (shp.get_class() if shp else "NONE")
	print("  ".repeat(depth) + node.name + " : " + node.get_class() + extra)
	for c in node.get_children():
		_dump(c, depth + 1)
