class_name DebugHudFormat
extends RefCounted

static func render(state: Dictionary) -> String:
	var lines = []

	# Line 1: Frame and time
	lines.append("[f%d %s]" % [state.frame, state.time])

	# Line 2: Camera position and direction
	var cam = state.camera
	lines.append("CAM pos%s dir%s" % [_format_vec(cam.pos), _format_vec(cam.dir)])

	# Line 3 (conditional): Bow state
	if state.has("bow"):
		var bow = state.bow
		lines.append("BOW draw=%.2f loaded=%s nock=%.2f" % [bow.draw, str(bow.loaded).to_lower(), bow.nock])

	# Lines 4+: Tracked objects
	for t in state.tracked:
		lines.append("%s pos%s rot%s" % [t.id, _format_vec(t.pos), _format_vec(t.rot_deg)])

	return "\n".join(lines)

static func _format_vec(v: Vector3) -> String:
	return "(%.2f, %.2f, %.2f)" % [v.x, v.y, v.z]
