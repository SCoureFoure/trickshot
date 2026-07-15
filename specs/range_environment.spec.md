# Range environment

## Requirement

`scenes/range_environment.tscn` dresses the archery range with KayKit props
that have physical presence (balls and arrows bounce off instead of ghosting
through) and a distant mountain vista that sells VR scale. It stays logic-free:
no scripts, no scoring — scoring targets live in `scenes/main.tscn`.

## Design decisions (pinned)

- Every near-field prop gets a colocated StaticBody3D sibling named
  `<Prop>Body` with a BoxShape3D approximation of its mesh AABB.
- Body transforms carry rotation + translation only; the prop's visual scale is
  baked into the shape size numbers. A scaled body basis silently double-sizes
  the shape (unit-scale checked to 0.01 tolerance — hand-authored rotation
  floats land ~1e-4 off).
- Anti-tunnel: every collision box dimension >= 0.5 (balls have no CCD).
- Trees collide over their full canopy AABB (user-reported: balls/arrows must
  not sail through foliage).
- Decorative (non-scoring) target butts removed — every target the player sees
  is a real scoring `archery_target.tscn` instance.
- Back wall row at z=-20 (behind the far z=-16 target), x -6/0/6; side wall row
  x=10 at z -2/-8/-14. Left flank stays open to the vista.
- Distant vista under a `Distant` Node3D: >= 3 `Mountain*` (z <= -40, scale
  >= 15) and >= 2 `Hill*` (z <= -30, scale >= 10) from the KayKit Medieval
  Hexagon pack, collision-free.

## Acceptance criteria

See check names in the test — one `_check` per criterion above, driven by the
`PROP_BODIES` prop list.

## Test

`scripts/test_range_environment_scene.gd`

## Non-goals

- Collision fidelity beyond box/column approximations.
- Walkable terrain on the vista (mountains are backdrop only).
- Prop interactivity (nothing here is grabbable).
