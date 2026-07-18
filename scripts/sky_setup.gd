class_name SkySetup
extends RefCounted

## Runtime configuration for the Sky3D addon node. Lives outside the tscn on
## purpose: Sky3D's exported setters are aliases guarded by `if tod:`/`if sky:`
## and silently drop values applied before its children exist. By the scene
## root's _ready they are built (child-first), so apply() is called from there.


static func apply(sky: Node) -> void:
	sky.game_time_enabled = false
	sky.current_time = 10.0
	sky.update_interval = 0.1
	sky.sky_contribution = 0.75
	sky.fog_enabled = false
	# Quest 2 hard constraint: no realtime shadows. SkyDome force-re-enables
	# shadow_enabled on every sun/moon energy update, so the kill must come
	# AFTER all time/sky config (time is frozen, so no further updates fire).
	# Opacity 0 keeps shadows invisible even if the day cycle is re-enabled.
	sky.sun_shadow_opacity = 0.0
	sky.moon_shadow_opacity = 0.0
	sky.sun.shadow_enabled = false
	sky.moon.shadow_enabled = false
