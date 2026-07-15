# Spec: Bow draw

## Requirement

Pure mapping from two-hand draw gesture to firing decision and launch speed for the bow-and-arrow system. The draw ratio translates hand separation distance to a [0, 1] value; a release fires only if the ratio meets the fire threshold; the launch speed is interpolated from minimum firing speed to maximum speed across the draw range.

## Design decisions (pinned)

- Hand separation at which the draw starts registering: `REST_DISTANCE = 0.15` meters. Below this the string is merely held (grabbing the string must not read as a partial draw).
- Hand separation that counts as a full draw: `MAX_DRAW = 0.5` meters.
- Minimum draw ratio for a release to fire an arrow: `FIRE_THRESHOLD = 0.2`.
- Arrow launch speed at the minimum firing draw: `MIN_SPEED = 5.0` m/s.
- Arrow launch speed at full draw: `MAX_SPEED = 30.0` m/s.
- Draw ratio is clamped to [0, 1].
- Sub-threshold release means no fire; arrow stays nocked and speed is 0.

## Acceptance criteria

- `zero_distance_zero_ratio`: `BowDraw.draw_ratio(0.0) == 0.0`
- `rest_distance_zero_ratio`: `BowDraw.draw_ratio(0.15) == 0.0`
- `half_draw`: `BowDraw.draw_ratio(0.325)` ≈ `0.5`
- `full_draw`: `BowDraw.draw_ratio(0.5)` ≈ `1.0`
- `over_draw_clamped`: `BowDraw.draw_ratio(2.0)` ≈ `1.0`
- `negative_distance_clamped`: `BowDraw.draw_ratio(-0.3) == 0.0`
- `below_threshold_no_fire`: `BowDraw.should_fire(0.19) == false`
- `at_threshold_fires`: `BowDraw.should_fire(0.2) == true`
- `no_fire_zero_speed`: `BowDraw.arrow_speed(0.1)` ≈ `0.0`
- `threshold_speed`: `BowDraw.arrow_speed(0.2)` ≈ `10.0`
- `full_draw_speed`: `BowDraw.arrow_speed(1.0)` ≈ `30.0`
- `overdrawn_speed_clamped`: `BowDraw.arrow_speed(1.5)` ≈ `30.0`

## Test

`scripts/test_bow_draw.gd` — run:

```
godot --headless --xr-mode off --path . --script res://scripts/test_bow_draw.gd
```

Prints `ALL_PASS` on success or `FAILURES=n` on failure.

## Non-goals

Arrow flight/stick behavior; bow scene wiring; animation blending.
