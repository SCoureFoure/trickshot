extends Node3D

## Entry point: start OpenXR when a runtime is present, otherwise fall back
## to a flat desktop preview so the scene stays runnable without a headset.

var xr_interface: XRInterface
var _score := Scoring.new()


func _ready() -> void:
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		# The headset compositor owns frame pacing; engine vsync would fight it.
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
	else:
		print("OpenXR not initialized - desktop preview mode")

	$Target.target_hit.connect(_on_target_hit)


func _on_target_hit(points: int) -> void:
	$ScoreLabel.text = str(_score.register(points))
