# Spec: Throw release velocity

## Requirement

Throw feel depends on release velocity computed from a short window of recent
controller positions, not instantaneous frame delta which is jittery.

## Design decisions (pinned)

- Window = 0.1 s.
- Max 16 samples.
- Velocity = (newest pos - oldest pos) / time span over surviving window.
- < 2 samples or zero span → Vector3.ZERO.
- Pure RefCounted module `ThrowSampler`, no nodes, headless-testable.

## Acceptance criteria

- Empty sampler: `release_velocity() == Vector3.ZERO`.
- Single sample: `release_velocity() == Vector3.ZERO`.
- Constant velocity `v = Vector3(2, 0, 1)` sampled at `t = 0.0` then every
  `1/90.0` s for 18 steps: `(release_velocity() - v).length() < 0.0001`.
- Stationary samples at `t` in `[0.0, 0.05]` followed by motion at
  `v = Vector3(3, 0, 0)` starting at `t = 1.0` sampled every `1/90.0` s for
  9 steps: result within `0.01` of `Vector3(3, 0, 0)` — stale samples must
  not drag the estimate down.
- Two samples at identical `t = 0.5` with different positions:
  `release_velocity() == Vector3.ZERO`.
- Motion `v = Vector3(0, 2, 0)` sampled every `1/90.0` s for 18 steps with
  deterministic alternating `+/- 0.002` noise on each position component:
  `(release_velocity() - v).length() < 0.1`.
- After `clear()` following several samples: `release_velocity() == Vector3.ZERO`.

## Test

`scripts/test_throw_sampler.gd` — run:

```
godot --headless --path . --script res://scripts/test_throw_sampler.gd
```

Prints `ALL_PASS` on success or `FAILURES=n` on failure.

## Non-goals

No arm/wrist pose modelling, no per-object release timing offsets yet —
tune later on device.
