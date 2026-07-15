class_name SpawnBudget
extends RefCounted

## Pure logic for the spawned-ball cap. Given how many balls are currently
## spawned (counting the one just added) and the cap, returns how many of
## the oldest spawned balls must be freed. A negative cap is treated as 0.


static func overflow(spawned_count: int, cap: int) -> int:
	return max(spawned_count - max(cap, 0), 0)
