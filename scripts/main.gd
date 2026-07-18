extends Node3D

## Entry point: start OpenXR when a runtime is present, otherwise fall back
## to a flat desktop preview so the scene stays runnable without a headset.
## Owns gameplay orchestration (spawning, scoring, reset); sky config and
## debug tooling live in SkySetup / DebugRig.

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
var _debug_rig: DebugRig


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

	SkySetup.apply($Sky3D)

	for target in [$TargetNear, $TargetMid, $TargetFar]:
		target.target_hit.connect(_on_target_hit)
	$XROrigin3D/LeftController.button_pressed.connect(_on_controller_button)
	$XROrigin3D/RightController.button_pressed.connect(_on_controller_button)
	$ButtonPanel/ResetButton.button_pressed.connect(func(_button): reset_scene())

	_setup_debug()


func _setup_debug() -> void:
	DebugRig.tag($OoTBow, "oot-bow")
	DebugRig.tag($OoTBow.get_node_or_null("NockedArrow"), "oot-bow-nocked")
	DebugRig.tag($Bow, "bow")
	DebugRig.tag($TargetNear, "target-near")
	DebugRig.tag($TargetMid, "target-mid")
	DebugRig.tag($TargetFar, "target-far")
	_debug_rig = DebugRig.new()
	add_child(_debug_rig)


func _on_target_hit(points: int) -> void:
	$ScoreLabel.text = str(_score.register(points))


func _on_controller_button(button_name: String) -> void:
	if button_name == "by_button":
		reset_scene()
	elif button_name == "primary_click":
		_debug_rig.capture($XROrigin3D/XRCamera3D)


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
