class_name DebugOverlay
extends Node3D

## Live debug visualization: HUD text + wireframe boxes around nodes in the
## "debug_tracked" group. Reads the DEBUG env var at startup; when disabled it
## stays inert (no HUD, no per-frame work).

## Debug readout doesn't need 72 Hz; rebuilding ImmediateMesh + reformatting the
## HUD every frame stalls the stereo (twice-rendered) pipeline and cost visible
## lag. Update at ~24 Hz instead.
const UPDATE_INTERVAL := 1.0 / 24.0

var _cfg: Dictionary
var _label: Label
var _boxes: Dictionary = {}
var _line_material: StandardMaterial3D
var _since_update := 0.0
var _vi_cache: Dictionary = {}
var _last_state: Dictionary = {}


## The most recently assembled HUD state — written to the screenshot JSON sidecar
## so a capture carries exact numbers, not pixels to OCR. Empty until first frame.
func get_last_state() -> Dictionary:
	return _last_state


func _ready() -> void:
	_cfg = DebugConfig.parse(DebugConfig.resolve_raw())
	if not _cfg.enabled:
		return

	var layer := CanvasLayer.new()
	add_child(layer)
	_label = Label.new()
	_label.position = Vector2(8, 8)
	layer.add_child(_label)


func _process(delta: float) -> void:
	if not _cfg.enabled or Engine.is_editor_hint():
		return
	_since_update += delta
	if _since_update < UPDATE_INTERVAL:
		return
	_since_update = 0.0

	var tracked: Array = []
	# One pass: build boxes + tracked list AND pick the bow for the BOW line.
	# Prefer the "oot-bow" id (the bow under active development); else any bow.
	var bow_state: Dictionary = {}
	for n in get_tree().get_nodes_in_group("debug_tracked"):
		if not n.has_meta("debug_id"):
			continue
		var id: String = n.get_meta("debug_id")
		if n.has_method("debug_state"):
			if id == "oot-bow":
				bow_state = n.debug_state()
			elif bow_state.is_empty():
				bow_state = n.debug_state()
		if not DebugConfig.should_track(_cfg, id):
			if _boxes.has(id):
				_boxes[id].visible = false
			continue

		var vi := _visual_for(n)
		if vi == null:
			continue

		var box := _get_or_create_box(id)
		var im: ImmediateMesh = box.mesh
		im.clear_surfaces()
		im.surface_begin(Mesh.PRIMITIVE_LINES, _line_material)
		for v in DebugWireGeometry.box_edges(vi.get_aabb()):
			im.surface_add_vertex(v)
		im.surface_end()
		box.global_transform = vi.global_transform
		box.visible = true

		tracked.append({
			"id": id,
			"pos": n.global_position,
			"rot_deg": n.global_rotation_degrees,
			# Local-to-parent: isolates an object's own pose (e.g. the nocked
			# arrow's slide) from the hand/bow motion that muddies global euler.
			"local_pos": n.position if n is Node3D else Vector3.ZERO,
			"local_rot": n.rotation_degrees if n is Node3D else Vector3.ZERO,
		})

	var cam := get_viewport().get_camera_3d()
	var cam_pos := Vector3.ZERO
	var cam_dir := Vector3(0, 0, -1)
	if cam != null:
		cam_pos = cam.global_position
		cam_dir = -cam.global_transform.basis.z

	var state := {
		"frame": Engine.get_frames_drawn(),
		"time": Time.get_time_string_from_system(),
		"camera": {"pos": cam_pos, "dir": cam_dir},
		"tracked": tracked,
	}
	if not bow_state.is_empty():
		state["bow"] = bow_state
	state["fps"] = Engine.get_frames_per_second()
	_last_state = state

	# fps appended outside the tested formatter so we can watch for lag.
	_label.text = "%s\nfps=%d" % [DebugHudFormat.render(state), state["fps"]]


## Cached visual-instance lookup: the recursive descendant search shouldn't run
## every update for a node whose subtree isn't changing.
func _visual_for(n: Node) -> VisualInstance3D:
	var key := n.get_instance_id()
	if _vi_cache.has(key):
		var cached = _vi_cache[key]
		if is_instance_valid(cached):
			return cached
	var vi := _find_visual_instance(n)
	_vi_cache[key] = vi
	return vi


func _find_visual_instance(n: Node) -> VisualInstance3D:
	if n is VisualInstance3D:
		return n
	return _find_visual_instance_descendant(n)


func _find_visual_instance_descendant(n: Node) -> VisualInstance3D:
	for child in n.get_children():
		if child is VisualInstance3D:
			return child
		var found := _find_visual_instance_descendant(child)
		if found != null:
			return found
	return null


func _get_or_create_box(id: String) -> MeshInstance3D:
	if _boxes.has(id):
		return _boxes[id]

	if _line_material == null:
		_line_material = StandardMaterial3D.new()
		_line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_line_material.albedo_color = Color(0.2, 1.0, 0.2)

	var box := MeshInstance3D.new()
	box.mesh = ImmediateMesh.new()
	add_child(box)
	_boxes[id] = box
	return box
