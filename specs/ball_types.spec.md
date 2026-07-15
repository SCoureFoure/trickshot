# Spec: Ball types

## Requirement

Four ball type variants — bouncy, beach, heavy, baseball — each a standalone
scene in `scenes/balls/` sharing `scripts/ball.gd`, differing only in physical
parameters and color. `scripts/ball_types.gd` (`BallTypes`) is the canonical
data table; each variant scene's properties must match its `BallTypes.TYPES`
entry.

## Design decisions (pinned)

- Variants are standalone scenes (no scene inheritance); root RigidBody3D +
  `ball.gd`, `collision_layer = 5`.
- Continuous collision detection stays OFF on all balls — Godot's ray-based CCD kills elastic bounce on fast impacts. Anti-tunneling is provided by thick static colliders instead (floor collision box 2 m deep, bounce wall 1 m thick, visible meshes unchanged).
- Ball type does NOT affect scoring.
- Values table (radius m / mass kg / bounce / friction / linear_damp / color):
  - bouncy: 0.06 / 0.15 / 0.85 / 0.6 / 0.0 / (0.2, 0.9, 0.3)
  - beach: 0.25 / 0.05 / 0.5 / 0.4 / 1.5 / (0.95, 0.35, 0.35)
  - heavy: 0.14 / 3.0 / 0.05 / 0.9 / 0.0 / (0.25, 0.25, 0.28)
  - baseball: 0.037 / 0.145 / 0.3 / 0.5 / 0.0 / (0.95, 0.95, 0.9)
- Beach ball spawns on the floor beside the rack (too large for the rack top);
  the other three spawn on the rack.
- `BallTypes.get_type(unknown)` returns `{}`.

## Acceptance criteria

- Module table: `BallTypes.TYPES` matches values above.
- Bouncy scene: `scenes/balls/ball_bouncy.tscn` (radius 0.06 m, mass 0.15 kg,
  bounce 0.85, friction 0.6, linear_damp 0.0, color (0.2, 0.9, 0.3), script
  `ball.gd`, collision_layer 5, in `balls` group).
- Beach scene: `scenes/balls/ball_beach.tscn` (radius 0.25 m, mass 0.05 kg,
  bounce 0.5, friction 0.4, linear_damp 1.5, color (0.95, 0.35, 0.35), script
  `ball.gd`, collision_layer 5, in `balls` group).
- Heavy scene: `scenes/balls/ball_heavy.tscn` (radius 0.14 m, mass 3.0 kg,
  bounce 0.05, friction 0.9, linear_damp 0.0, color (0.25, 0.25, 0.28), script
  `ball.gd`, collision_layer 5, in `balls` group).
- Baseball scene: `scenes/balls/ball_baseball.tscn` (radius 0.037 m, mass
  0.145 kg, bounce 0.3, friction 0.5, linear_damp 0.0, color (0.95, 0.95,
  0.9), script `ball.gd`, collision_layer 5, in `balls` group).

## Test

`scripts/test_ball_types.gd` — run:

```
godot --headless --xr-mode off --path . --script res://scripts/test_ball_types.gd
```

Prints `ALL_PASS` on success or `FAILURES=n` on failure.

## Non-goals

Per-type scoring multipliers; aerodynamics/spin effects; frisbees; textures or
striped materials (flat albedo only).
