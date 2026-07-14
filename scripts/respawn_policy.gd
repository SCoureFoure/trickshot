class_name RespawnPolicy
extends RefCounted

## Decides when a ball should return to its rack home. Pinned constants and
## rules ensure active rigid-body count stays bounded.

const FLOOR_Y := -2.0
const REST_TIMEOUT := 5.0
const REST_SPEED := 0.1


static func should_respawn(held: bool, seconds_since_release: float, y: float, speed: float) -> bool:
	## Apply respawn rules in priority order.
	##
	## 1. held == true → false (held ball never respawns).
	## 2. y < FLOOR_Y → true (fell out of world).
	## 3. seconds_since_release < 0.0 → false (sentinel: never released).
	## 4. seconds_since_release > REST_TIMEOUT and speed < REST_SPEED → true (rested long enough).
	## 5. Otherwise → false.

	# Rule 1: Held ball wins regardless of other conditions.
	if held:
		return false

	# Rule 2: Below floor threshold.
	if y < FLOOR_Y:
		return true

	# Rule 3: Never released sentinel.
	if seconds_since_release < 0.0:
		return false

	# Rule 4: Rested past timeout AND moving slowly.
	if seconds_since_release > REST_TIMEOUT and speed < REST_SPEED:
		return true

	# Rule 5: All other cases.
	return false
