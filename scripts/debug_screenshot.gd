class_name DebugScreenshot
extends RefCounted

## Writes debug captures under res://debug/screenshots as shot_<frame>.{png,json}.
##
## PNG: the XR main viewport renders to a write-only OpenXR swapchain, so
## get_image() on it is ALWAYS empty. The caller instead renders a mono mirror
## through a shared-world SubViewport (CPU-readable) and passes that Image here.
##
## JSON: an authoritative sidecar of the debug HUD state for the same frame —
## exact numbers the analyze-screenshot skill reads instead of OCRing pixels.

static func _dir() -> String:
	var dir_path := ProjectSettings.globalize_path("res://debug/screenshots")
	var err := DirAccess.make_dir_recursive_absolute(dir_path)
	if err != OK and err != ERR_ALREADY_EXISTS:
		return ""
	return dir_path


## Saves an already-captured Image. Returns full path, or "" on failure/empty.
static func save_image(img: Image, frame: int) -> String:
	if img == null or img.is_empty():
		return ""
	var dir_path := _dir()
	if dir_path == "":
		return ""
	var full_path := dir_path.path_join("shot_%d.png" % frame)
	if img.save_png(full_path) != OK:
		return ""
	return full_path


## Saves the debug state dict as a JSON sidecar. Returns full path, or "".
static func save_state_sidecar(state: Dictionary, frame: int) -> String:
	if state.is_empty():
		return ""
	var dir_path := _dir()
	if dir_path == "":
		return ""
	var full_path := dir_path.path_join("shot_%d.json" % frame)
	var f := FileAccess.open(full_path, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string(JSON.stringify(_jsonify(state), "  "))
	f.close()
	return full_path


## Recursively converts Vector3s (and nested dicts/arrays) to JSON-friendly
## values so the sidecar is human- and machine-readable.
static func _jsonify(v: Variant) -> Variant:
	if v is Vector3:
		return {"x": v.x, "y": v.y, "z": v.z}
	if v is Dictionary:
		var out := {}
		for k in v:
			out[k] = _jsonify(v[k])
		return out
	if v is Array:
		var out := []
		for e in v:
			out.append(_jsonify(e))
		return out
	return v
