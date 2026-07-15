class_name BallTypes
extends RefCounted

## Data table for ball type variants, one entry per variant scene in scenes/balls/.

const TYPES := {
	"bouncy": {
		"radius": 0.06, "mass": 0.15, "bounce": 0.85, "friction": 0.6,
		"linear_damp": 0.0, "color": Color(0.2, 0.9, 0.3),
	},
	"beach": {
		"radius": 0.25, "mass": 0.05, "bounce": 0.5, "friction": 0.4,
		"linear_damp": 1.5, "color": Color(0.95, 0.35, 0.35),
	},
	"heavy": {
		"radius": 0.14, "mass": 3.0, "bounce": 0.05, "friction": 0.9,
		"linear_damp": 0.0, "color": Color(0.25, 0.25, 0.28),
	},
	"baseball": {
		"radius": 0.037, "mass": 0.145, "bounce": 0.3, "friction": 0.5,
		"linear_damp": 0.0, "color": Color(0.95, 0.95, 0.9),
	},
}


static func names() -> Array:
	return TYPES.keys()


static func get_type(type_name: String) -> Dictionary:
	if type_name in TYPES:
		return TYPES[type_name]
	return {}
