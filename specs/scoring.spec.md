# Spec: Scoring

## Requirement

Target hits award points based on the distance from the target centre. The
player's running total score accumulates points for valid (positive) hits.

## Design decisions (pinned)

- Ring radii: 0.15 m, 0.30 m, 0.45 m (inner to outer).
- Ring points: 25, 10, 5 points respectively.
- Boundaries are inclusive: distance <= 0.15 m awards 25 points, <= 0.30 m
  awards 10 points, <= 0.45 m awards 5 points, > 0.45 m awards 0 points.
- Negative or zero distances are invalid and return 0 points.
- Non-positive points (0 or negative) do not update the running total.
- Pure RefCounted module `Scoring`, no nodes, headless-testable.

## Acceptance criteria

- `points_for_ring_distance(0.0) == 25`: zero distance (bullseye).
- `points_for_ring_distance(0.15) == 25`: boundary at 0.15 m (inclusive).
- `points_for_ring_distance(0.1500001) == 10`: just outside first ring.
- `points_for_ring_distance(0.30) == 10`: boundary at 0.30 m (inclusive).
- `points_for_ring_distance(0.45) == 5`: boundary at 0.45 m (inclusive).
- `points_for_ring_distance(0.46) == 0`: just outside third ring.
- `points_for_ring_distance(-0.01) == 0`: negative distance (invalid).
- Fresh `Scoring` instance: `total == 0`.
- `register(25)` returns 25 and updates `total` to 25.
- `register(5)` then returns 30 and updates `total` to 30.
- `register(0)` returns 30 and leaves `total` unchanged at 30 (zero is not
  added).
- `register(-10)` returns 30 and leaves `total` unchanged at 30 (negative is
  not added).
- `reset()` sets `total` back to 0.

## Test

`scripts/test_scoring.gd` — run:

```
godot --headless --xr-mode off --path . --script res://scripts/test_scoring.gd
```

Prints `ALL_PASS` on success or `FAILURES=n` on failure.

## Non-goals

Combo multipliers, per-object score values, persistence, UI display.
