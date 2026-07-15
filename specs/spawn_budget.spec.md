# Spec: Spawn budget

## Requirement

Cap the number of button-spawned balls to protect Quest 2 frame rate; when a spawn exceeds the cap, the oldest spawned balls are freed. `SpawnBudget.overflow(spawned_count, cap)` returns the number to free.

## Design decisions (pinned)

- Cap lives in `scripts/main.gd` (`SPAWN_CAP = 10`).
- Rack balls never count against the cap.
- Negative cap treated as 0.
- Eviction order is oldest-first (caller's responsibility).

## Acceptance criteria

- `under_cap_zero`: `SpawnBudget.overflow(3, 10) == 0`
- `at_cap_zero`: `SpawnBudget.overflow(10, 10) == 0`
- `one_over_cap`: `SpawnBudget.overflow(11, 10) == 1`
- `three_over_cap`: `SpawnBudget.overflow(13, 10) == 3`
- `zero_count_zero`: `SpawnBudget.overflow(0, 10) == 0`
- `zero_cap_frees_all`: `SpawnBudget.overflow(4, 0) == 4`
- `negative_cap_as_zero`: `SpawnBudget.overflow(2, -5) == 2`

## Test

`scripts/test_spawn_budget.gd` — run:

```
godot --headless --xr-mode off --path . --script res://scripts/test_spawn_budget.gd
```

Prints `ALL_PASS` on success or `FAILURES=n` on failure.

## Non-goals

Per-type caps; despawn timers.
