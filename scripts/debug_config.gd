class_name DebugConfig
extends RefCounted

static func parse(raw: String) -> Dictionary:
	var trimmed = raw.strip_edges()
	var lower = trimmed.to_lower()

	if lower == "" or lower == "false" or lower == "0":
		return {"enabled": false, "all": false, "ids": PackedStringArray()}
	elif lower == "true" or lower == "1":
		return {"enabled": true, "all": true, "ids": PackedStringArray()}
	else:
		# It's an id list: split raw on comma, trim each segment, drop empty
		var parts = raw.split(",")
		var ids = PackedStringArray()
		for part in parts:
			var trimmed_part = part.strip_edges()
			if trimmed_part != "":
				ids.append(trimmed_part)
		return {"enabled": true, "all": false, "ids": ids}

## Resolves the raw DEBUG value. A non-empty DEBUG OS environment variable wins
## (shell override); otherwise a root `debug.env` file is read (so it can be
## toggled without a shell — edit the file and relaunch, e.g. on-device). The
## file is a dotenv-style `DEBUG=<value>` line; `#` comments and blanks ignored.
static func resolve_raw() -> String:
	var env := OS.get_environment("DEBUG")
	if env.strip_edges() != "":
		return env
	var path := "res://debug.env"
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		if f != null:
			while not f.eof_reached():
				var line := f.get_line().strip_edges()
				if line == "" or line.begins_with("#"):
					continue
				if line.begins_with("DEBUG="):
					var v := line.substr(6).strip_edges()
					return v.trim_prefix("\"").trim_suffix("\"")
	return OS.get_environment("DEBUG")


static func should_track(cfg: Dictionary, debug_id: String) -> bool:
	if cfg.enabled == false:
		return false
	if cfg.all == true:
		return true
	return debug_id in cfg.ids
