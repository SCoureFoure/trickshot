class_name DebugRig
extends Node

## Self-contained debug tooling: the wireframe/HUD overlay, the screenshot
## pipeline, and its confirmation flash. Main only tags game objects and
## forwards the capture button here; when DEBUG is off the overlay gates
## itself inert (see debug_overlay.gd / the analyze-screenshot skill).

var _overlay: DebugOverlay
var _flash_label: Label
var _cap_viewport: SubViewport
var _cap_camera: Camera3D


## Marks a node as inspectable by the debug overlay: a stable id + group
## membership so the overlay can find it without a per-frame tree walk.
static func tag(node: Node, id: String) -> void:
	if node == null:
		return
	node.set_meta("debug_id", id)
	node.add_to_group("debug_tracked")


func _ready() -> void:
	_overlay = DebugOverlay.new()
	add_child(_overlay)
	_setup_flash()
	_setup_capture()


## A brief, comfort-safe HUD confirmation when a screenshot lands: a small
## fading caption top-center (no full-screen flash — the owner gets motion sick).
func _setup_flash() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_flash_label = Label.new()
	_flash_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_flash_label.position = Vector2(0, 40)
	_flash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_flash_label.modulate.a = 0.0
	layer.add_child(_flash_label)


## A hidden SubViewport that shares the main World3D (own_world_3d = false), so
## its camera renders the same scene. The XR main viewport draws to a write-only
## OpenXR swapchain whose get_image() is always empty; this mirror IS
## CPU-readable. Idle (UPDATE_DISABLED) until a capture is requested.
func _setup_capture() -> void:
	_cap_viewport = SubViewport.new()
	_cap_viewport.size = Vector2i(1280, 720)
	_cap_viewport.own_world_3d = false
	_cap_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_cap_viewport)
	_cap_camera = Camera3D.new()
	_cap_camera.current = true
	_cap_viewport.add_child(_cap_camera)


## Saves a mirror PNG from the given camera's viewpoint plus the overlay's
## authoritative JSON state sidecar for the same frame.
func capture(view_camera: Camera3D) -> void:
	var frame := Engine.get_frames_drawn()

	# Render one mirror frame from the headset viewpoint into the readable viewport.
	var img: Image = null
	if _cap_viewport != null:
		if view_camera != null:
			_cap_camera.global_transform = view_camera.global_transform
			_cap_camera.fov = view_camera.fov
		_cap_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		img = _cap_viewport.get_texture().get_image()

	var png := DebugScreenshot.save_image(img, frame)
	var json := ""
	if _overlay != null:
		json = DebugScreenshot.save_state_sidecar(_overlay.get_last_state(), frame)

	if png == "" and json == "":
		push_warning("screenshot capture produced nothing (DEBUG off + mirror empty?)")
		return
	print("captured: png=%s json=%s" % [png, json])
	_flash("shot_%d" % frame)


func _flash(file_name: String) -> void:
	if _flash_label == null:
		return
	_flash_label.text = "📸 %s" % file_name
	_flash_label.modulate.a = 1.0
	create_tween().tween_property(_flash_label, "modulate:a", 0.0, 0.8)
