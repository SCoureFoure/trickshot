extends Node3D

## Entry point: start OpenXR when a runtime is present, otherwise fall back
## to a flat desktop preview so the scene stays runnable without a headset.

var xr_interface: XRInterface
var _score := Scoring.new()
const BALL_SCENES := {
	"bouncy": preload("res://scenes/balls/ball_bouncy.tscn"),
	"beach": preload("res://scenes/balls/ball_beach.tscn"),
	"heavy": preload("res://scenes/balls/ball_heavy.tscn"),
	"baseball": preload("res://scenes/balls/ball_baseball.tscn"),
}
const SPAWN_CAP := 10
const SPAWN_POINT := Vector3(0.35, 1.0, 0.8)

var _spawned: Array = []
var _debug_overlay: DebugOverlay
var _flash_label: Label
var _cap_viewport: SubViewport
var _cap_camera: Camera3D


func _ready() -> void:
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		# The headset compositor owns frame pacing; engine vsync would fight it.
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
	else:
		print("OpenXR not initialized - desktop preview mode")
		# Playspace is yawed -90 deg (range at the player's physical left).
		# Desktop preview has no head tracking, so aim the camera back
		# downrange to keep the flat preview useful.
		$XROrigin3D/XRCamera3D.rotation.y = PI / 2

	# Sky3D config must happen here, not in the tscn: its exported setters are
	# aliases guarded by `if tod:`/`if sky:` and silently drop values applied
	# before its children exist. By our _ready they are built (child-first).
	$Sky3D.game_time_enabled = false
	$Sky3D.current_time = 10.0
	$Sky3D.update_interval = 0.1
	$Sky3D.sky_contribution = 0.75
	$Sky3D.fog_enabled = false
	# Quest 2 hard constraint: no realtime shadows. SkyDome force-re-enables
	# shadow_enabled on every sun/moon energy update, so the kill must come
	# AFTER all time/sky config (time is frozen, so no further updates fire).
	# Opacity 0 keeps shadows invisible even if the day cycle is re-enabled.
	$Sky3D.sun_shadow_opacity = 0.0
	$Sky3D.moon_shadow_opacity = 0.0
	$Sky3D.sun.shadow_enabled = false
	$Sky3D.moon.shadow_enabled = false

	for target in [$TargetNear, $TargetMid, $TargetFar]:
		target.target_hit.connect(_on_target_hit)
	$XROrigin3D/LeftController.button_pressed.connect(_on_controller_button)
	$XROrigin3D/RightController.button_pressed.connect(_on_controller_button)
	$ButtonPanel/ResetButton.button_pressed.connect(func(_button): reset_scene())

	# Debug tooling: tag inspectable objects, then add the overlay (inert unless
	# the DEBUG env var is set — see debug_overlay.gd / analyze-screenshot skill).
	_tag_debug($OoTBow, "oot-bow")
	_tag_debug($OoTBow.get_node_or_null("NockedArrow"), "oot-bow-nocked")
	_tag_debug($Bow, "bow")
	_tag_debug($TargetNear, "target-near")
	_tag_debug($TargetMid, "target-mid")
	_tag_debug($TargetFar, "target-far")
	_debug_overlay = DebugOverlay.new()
	add_child(_debug_overlay)
	_setup_screenshot_flash()
	_setup_capture()


## Marks a node as inspectable by the debug overlay: a stable id + group
## membership so the overlay can find it without a per-frame tree walk.
func _tag_debug(node: Node, id: String) -> void:
	if node == null:
		return
	node.set_meta("debug_id", id)
	node.add_to_group("debug_tracked")


func _on_target_hit(points: int) -> void:
	$ScoreLabel.text = str(_score.register(points))


func _on_controller_button(button_name: String) -> void:
	if button_name == "by_button":
		reset_scene()
	elif button_name == "primary_click":
		_capture_screenshot()


## A brief, comfort-safe HUD confirmation when a screenshot lands: a small
## fading caption top-center (no full-screen flash — the owner gets motion sick).
func _setup_screenshot_flash() -> void:
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


func _capture_screenshot() -> void:
	var frame := Engine.get_frames_drawn()

	# Render one mirror frame from the headset viewpoint into the readable viewport.
	var img: Image = null
	if _cap_viewport != null:
		var xr_cam := $XROrigin3D/XRCamera3D
		if xr_cam != null:
			_cap_camera.global_transform = xr_cam.global_transform
			_cap_camera.fov = xr_cam.fov
		_cap_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		img = _cap_viewport.get_texture().get_image()

	var png := DebugScreenshot.save_image(img, frame)
	var json := ""
	if _debug_overlay != null:
		json = DebugScreenshot.save_state_sidecar(_debug_overlay.get_last_state(), frame)

	if png == "" and json == "":
		push_warning("screenshot capture produced nothing (DEBUG off + mirror empty?)")
		return
	print("captured: png=%s json=%s" % [png, json])
	_flash_screenshot("shot_%d" % frame)


func _flash_screenshot(file_name: String) -> void:
	if _flash_label == null:
		return
	_flash_label.text = "📸 %s" % file_name
	_flash_label.modulate.a = 1.0
	create_tween().tween_property(_flash_label, "modulate:a", 0.0, 0.8)


func reset_balls() -> void:
	for ball in get_tree().get_nodes_in_group("balls"):
		ball.respawn()


## Spawns a fresh ball of the given type at SPAWN_POINT. When the number of
## spawned balls exceeds SPAWN_CAP, the oldest spawned balls are freed.
func spawn_ball(type_name: String) -> void:
	var scene: PackedScene = BALL_SCENES.get(type_name)
	if scene == null:
		return
	var ball := scene.instantiate()
	ball.position = SPAWN_POINT
	add_child(ball)
	_spawned.append(ball)
	for i in SpawnBudget.overflow(_spawned.size(), SPAWN_CAP):
		var oldest = _spawned.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()


## Full reset: frees every spawned ball, returns rack balls home, zeroes score.
func reset_scene() -> void:
	for spawned in _spawned:
		if is_instance_valid(spawned):
			spawned.queue_free()
	_spawned.clear()
	for arrow in get_tree().get_nodes_in_group("arrows"):
		arrow.queue_free()
	for bow in [$Bow, $OoTBow]:
		var zone = bow.get_node_or_null("NockZone")
		if zone != null and zone.has_snapped_object():
			zone.drop_object()
		bow.unload_arrow()
	for loose in get_tree().get_nodes_in_group("nockable"):
		loose.reset_to_home()
	$Bow.reset_to_home()
	$OoTBow.reset_to_home()
	reset_balls()
	_score = Scoring.new()
	$ScoreLabel.text = "0"
