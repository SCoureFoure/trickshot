class_name BowDraw
extends RefCounted

## Pure logic for the bow draw: maps the distance between the bow hand and
## the string hand to a draw ratio, decides whether a release fires, and
## maps the ratio to arrow launch speed.

## Hand separation that counts as a full draw, in meters.
const MAX_DRAW := 0.5

## Hand separation at which the draw starts registering, in meters. Below
## this the string is merely held (grabbing the string must not read as a
## partial draw).
const REST_DISTANCE := 0.15

## Minimum draw ratio for a release to fire an arrow.
const FIRE_THRESHOLD := 0.2

## Arrow launch speed at the minimum firing draw, in m/s.
const MIN_SPEED := 5.0

## Arrow launch speed at full draw, in m/s.
const MAX_SPEED := 30.0


## Returns the draw ratio in [0, 1] for a hand separation in meters.
## Ratio is 0 at or below REST_DISTANCE and 1 at or above MAX_DRAW.
static func draw_ratio(hand_distance: float) -> float:
	return clampf((hand_distance - REST_DISTANCE) / (MAX_DRAW - REST_DISTANCE), 0.0, 1.0)


## Returns true when releasing at this draw ratio should fire an arrow.
static func should_fire(ratio: float) -> bool:
	return ratio >= FIRE_THRESHOLD


## Returns the arrow launch speed in m/s for a draw ratio. Ratios below the
## fire threshold return 0.0 (no fire).
static func arrow_speed(ratio: float) -> float:
	if not should_fire(ratio):
		return 0.0
	return lerpf(MIN_SPEED, MAX_SPEED, clampf(ratio, 0.0, 1.0))
