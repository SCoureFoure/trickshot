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
const SPAWN_POINT := Vector3(0.5, 1.0, -0.35)

var _spawned: Array = []


func _ready() -> void:
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		# The headset compositor owns frame pacing; engine vsync would fight it.
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
	else:
		print("OpenXR not initialized - desktop preview mode")

	$Target.target_hit.connect(_on_target_hit)
	$XROrigin3D/LeftController.button_pressed.connect(_on_controller_button)
	$XROrigin3D/RightController.button_pressed.connect(_on_controller_button)
	$ButtonPanel/ResetButton.button_pressed.connect(func(_button): reset_scene())
	$ButtonPanel/BouncySpawnButton.button_pressed.connect(func(_button): spawn_ball("bouncy"))
	$ButtonPanel/BeachSpawnButton.button_pressed.connect(func(_button): spawn_ball("beach"))
	$ButtonPanel/HeavySpawnButton.button_pressed.connect(func(_button): spawn_ball("heavy"))
	$ButtonPanel/BaseballSpawnButton.button_pressed.connect(func(_button): spawn_ball("baseball"))


func _on_target_hit(points: int) -> void:
	$ScoreLabel.text = str(_score.register(points))


func _on_controller_button(button_name: String) -> void:
	if button_name == "by_button":
		reset_scene()


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
	$Bow.reset_to_home()
	reset_balls()
	_score = Scoring.new()
	$ScoreLabel.text = "0"
