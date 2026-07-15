# Spec: Environment collision shapes

## Requirement

Scenery assets must have appropriate collision shapes generated at import time,
so balls and arrows interact physically with environment props without
hand-authored bodies, while distant decoration (mountains, hills) has no
collision for performance.

## Design decisions (pinned)

- Scenery collision is generated at import time via `.gltf.import` `_subresources`
  (see `.claude/skills/import-asset/SKILL.md`).
- Concave scenery (building, tent, weaponrack) uses Trimesh (ConcavePolygonShape3D).
- Convex-ish scenery (bucket, barrel, sack, rock, wall) uses Simple Convex (ConvexPolygonShape3D).
- Distant decoration (mountains, hills) has no collision.
- Trees are no longer import-trimesh. Trees use wrapper scenes
  `scenes/env/tree_a.tscn` / `scenes/env/tree_b.tscn` (`scripts/tree_drag.gd`):
  a solid trunk cylinder (`StaticBody3D`) plus a canopy drag zone (`Area3D`,
  `linear_damp_space_override = SPACE_OVERRIDE_COMBINE`, `linear_damp = 1.2`)
  that slows projectiles passing through the leaves instead of stopping them.
  With linear damp `c` the exit speed over path `x` is `v − c·x`, so
  `canopy_linear_damp` is tuned such that `v0/c` exceeds the canopy diameter
  or projectiles would stall inside the canopy.
- `scenes/range_environment.tscn` contains no hand-placed collision bodies at the root level.

## Acceptance criteria

- Each of 3 concave assets (building_archeryrange_red, tent, weaponrack)
  instantiated: at least one descendant `CollisionShape3D` exists whose shape class is
  `ConcavePolygonShape3D`.
- Each of 5 convex assets (bucket_arrows, barrel, sack, rock_single_C, wall_straight)
  instantiated: at least one descendant `CollisionShape3D` exists whose shape class is
  `ConvexPolygonShape3D`.
- `tree_single_A.gltf` and `tree_single_B.gltf` instantiated: zero `CollisionShape3D`
  nodes exist anywhere in the tree (collision now lives in the wrapper scenes).
- `mountain_A.gltf` instantiated: zero `CollisionShape3D` nodes exist anywhere in the tree.
- `range_environment.tscn` instantiated: zero direct children of the root are `StaticBody3D`.
- `range_environment.tscn` instantiated: at least 15 `CollisionShape3D` nodes exist anywhere in the tree.
- `range_environment.tscn` instantiated: root has children named `TreeA1` and `TreeB2`
  whose script resource path is `res://scripts/tree_drag.gd`.
- `tree_a.tscn` / `tree_b.tscn` instantiated (`_ready` triggered): `Trunk/CollisionShape3D.shape`
  is `CylinderShape3D` with radius 0.54 / 0.57; `Canopy` is an `Area3D` with
  `linear_damp_space_override == SPACE_OVERRIDE_COMBINE`, `linear_damp == 1.2`,
  `collision_mask & 1 != 0`; `Canopy/CollisionShape3D.shape` is `CylinderShape3D`
  with radius 1.92 / 2.28. Setting `tree_scale` before `add_child` scales trunk
  radius proportionally.
- A ball passing through the canopy is slowed but not stopped (drag, not a solid
  wall or a no-op zone).

## Test

`scripts/test_env_collision.gd` — run:

```
godot --headless --xr-mode off --path . --script res://scripts/test_env_collision.gd
```

Prints `ALL_PASS` on success or `FAILURES=n` on failure.
