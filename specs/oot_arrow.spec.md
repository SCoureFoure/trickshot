# Spec: OoT Arrow scene

## Requirement

Fired arrow projectile using the OoT mesh model that flies nose-first under
engine gravity, sticks into the first surface hit (raycast-based collision
detection between physics positions to prevent tunneling), and cleans itself up
after timing out. Identical flight/stick/expiry behavior to the KayKit arrow,
differing only in mesh and fitted collision capsule.

## Design decisions (pinned)

- Reuses `scripts/arrow.gd` unchanged.
- Mesh path: `res://assets/oot/arrow.glb`.
- Mesh rotation: +X tip rotated onto scene -Z (arrow tip direction).
- Mesh scale: 1 (model is 0.949 units long, plausible real arrow length).
- Capsule shape: radius 0.02 m, height 0.9 m, rotated along Z axis with
  -0.106 m offset (centered at mesh z midpoint: tip -0.580, tail +0.368).
- No continuous collision detection: raycast between physics positions covers
  tunneling; CCD kills bounce project-wide.
- The stick raycast runs TIP-to-tip: with this arrow's 0.55 m nose, an
  origin-path ray never reached a surface the capsule had already stopped
  against, so OoT arrows bounced off targets KayKit arrows stuck into.
  `tip_length = 0.55` (export) matches the capsule front extent.
- On stick the nose buries `STICK_PENETRATION = 0.2` m: origin lands
  `tip_length - 0.2 = 0.35` behind the hit point.
- Engine gravity (no manual gravity script): arrow falls under Godot's standard
  physics.
- Constants: `STUCK_LIFETIME = 10.0` s, `MAX_FLIGHT_TIME = 30.0` s,
  `MIN_ORIENT_SPEED = 0.5` m/s.
- Collision layer 5, same as balls and KayKit arrow, so target Face area
  detects arrows.
- Mass 0.1 kg.
- Arrow tip assumed at -Z (Godot forward direction).

## Acceptance criteria

1. `scene_loads`: `scenes/oot_arrow.tscn` is a valid PackedScene that
   instantiates and can be added to the scene tree.
2. `is_rigid_body`: Arrow is a RigidBody3D.
3. `script_is_arrow_gd`: Arrow's script resource_path is exactly
   `"res://scripts/arrow.gd"`.
4. `in_arrows_group`: Arrow is in the `"arrows"` group.
5. `on_layer_5`: Arrow's collision_layer is 5.
6. `fire_sets_velocity`: After `arrow.fire(20.0)`, the linear_velocity is
   approximately `-arrow.global_transform.basis.z * 20.0` (within 0.001 m/s).
7. `stick_freezes`: After `arrow.stick(Vector3(1, 1, 1))`, arrow.freeze is
   true, linear_velocity is zero, and global_position is approximately
   Vector3(1, 1, 1.35) (origin parked 0.35 m behind the hit along +Z at
   default orientation; within 0.001 m).
7b. `tip_length_matches_capsule`: `tip_length == 0.55`.
7c. `fired_arrow_sticks_in_wall` / `stuck_at_wall_face`: an arrow fired at
    15 m/s into a StaticBody3D box wall 3 m downrange ends frozen at the wall
    face within 300 physics frames (real simulated flight — the regression
    membrane for the bounce bug).
8. `stuck_arrow_expires`: After stick and calling `_physics_process(11.0)`, the
   arrow is queued for deletion.
9. `flight_timeout_expires`: After firing with speed 5.0 and calling
   `_physics_process(31.0)`, the arrow is queued for deletion.
10. `void_fall_expires`: After firing with speed 5.0, setting global_position
    to Vector3(0, -10, 0), and calling `_physics_process(0.1)`, the arrow is
    queued for deletion.

## Test

`scripts/test_oot_arrow_scene.gd` — run:

```
godot --headless --xr-mode off --path . --script res://scripts/test_oot_arrow_scene.gd
```

Prints `ALL_PASS` on success or `FAILURES=n` on failure.

## Non-goals

Replacing the KayKit arrow; bow interaction wiring; nock/pickup behavior (later
phase); scoring rules (target-side); arrow retrieval.
