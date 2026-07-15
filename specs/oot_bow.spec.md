# Spec: OoT Bow scene

## Requirement

A second two-hand bow using the rigged OoT model (`assets/oot/bow.glb`),
coexisting with the existing KayKit bow (`scenes/bow.tscn`) — neither
replaces the other. The first grabbing hand holds the grip (primary); the
second grabs the string (secondary). Draw ratio comes from BowDraw applied
to the distance between the two hands. The limb bend and string are shown
by blending the imported single-pose animations `idle` (rest) and
`Pull bow` (full draw) on an AnimationTree, driven by the draw ratio.
Releasing the string at or above the fire threshold spawns an arrow at the
Spawn node from `scenes/oot_arrow.tscn` and fires it; below the threshold
the arrow is quietly un-nocked.

## Design decisions (pinned)

- Separate scene/script (`scenes/oot_bow.tscn` / `scripts/oot_bow.gd`);
  `scenes/bow.tscn` and `scripts/bow.gd` are untouched.
- No `class_name` on `oot_bow.gd` — `Bow` is taken by `bow.gd` and nothing
  references the new type; also avoids the re-import gotcha.
- Grab order determines role, not grab-point mode: the first hand to grab
  becomes `_grip_hand`, the second becomes `_string_hand`.
- Releasing the grip hand drops everything (clears both hands); releasing
  the string hand alone never clears `_grip_hand`.
- `second_hand_grab = 2` (`SecondHandGrab.SECOND`) is required for the
  second grab to register at all.
- Constants derived from the GLB (armature scale 0.652), from the
  Pull_String bone: `NOCK_PULL = 0.497`, `STRING_REST = 0.284`.
  `NOCK_TAIL_OFFSET = 0.368` is model units at scale 1. `NOCK_HEIGHT = 0.0`
  (model string centerline is at y=0 after rotation).
- Draw visual is an `AnimationTree` with an `AnimationNodeBlendTree`
  blending `idle` and `Pull bow` via `AnimationNodeBlend2`; `_draw` drives
  `parameters/blend/blend_amount` each frame. Both imported clips are
  single-keyframe poses (0.0417s), so scrubbing one clip cannot work — pose
  blending is the only reading.
- No procedural string mesh (`StringTop`/`StringBottom`) — the rigged model
  supplies the string via the blended pose.
- Bow mesh basis remap: `Transform3D(0, -1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0)`
  (model +X limbs onto scene +Y; string pull stays +Z; limb tips land at
  y ±0.645 so the existing 1.3-tall bow_shape still fits).
- Arrow mesh tip is the +X end (dense arrowhead verts at xmax, flat fins at
  xmin) — owner verifies visually on headset.
- `NockedArrow` transform:
  `Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, 0, 0, -0.084)` (model +X tip onto
  scene -Z; rest z = STRING_REST - NOCK_TAIL_OFFSET = -0.084, y = 0).
- `StringGrabLeft`/`StringGrabRight` rest at z = 0.284 (rest nock position
  of the new model), `drive_position = 0.0`, `drive_angle = 0.0`,
  `drive_aim = 1.0`.
- Mass 1.2 kg; collision layer 5 (same as balls/arrows).
- Shares `BowDraw` for draw/fire math; fires `scenes/oot_arrow.tscn`.
- `reset_to_home()` restores the bow's transform and zeroes velocities, for
  the scene reset button.

## Acceptance criteria

1. `scene_loads`: `scenes/oot_bow.tscn` is a valid PackedScene that
   instantiates and can be added to the scene tree.
2. `script_is_oot_bow_gd`: script resource_path is exactly
   `"res://scripts/oot_bow.gd"`.
3. `second_hand_grab_enabled`: `bow.second_hand_grab == 2`.
4. `has_spawn_node`: `bow.get_node_or_null("Spawn") != null`.
5. `grab_points_configured`: exactly 2 children with a script ending
   `grab_point_hand.gd` and `mode == 1` (grip), and exactly 2 with
   `mode == 2` (string).
6. `draw_tracks_hands`: after grabbing with two hands 0.5 m apart,
   `abs(bow._draw - 1.0) < 0.0001`.
7. `nocked_arrow_visible_when_drawn`: `NockedArrow.visible == true` while
   drawn.
8. `has_animation_tree`: the bow has a child `AnimationTree` with
   `active == true`.
9. `blend_tracks_draw`: at draw 1.0, `parameters/blend/blend_amount` on the
   AnimationTree equals `1.0` within `0.0001`.
10. `mesh_has_pose_animations`: the `AnimationPlayer` under `Mesh` has both
    `idle` and `Pull bow` animations.
11. `nocked_arrow_tail_on_string`: while drawn, `NockedArrow.position.z`
    equals `STRING_REST + NOCK_PULL * _draw - NOCK_TAIL_OFFSET`.
12. `fires_arrow_on_release`: releasing the string hand at draw 1.0 leaves
    exactly one node in group `"arrows"` with `linear_velocity.length()`
    approximately `30.0` (`BowDraw.arrow_speed(1.0)`).
13. `string_resets_after_fire`: after firing, `bow._draw == 0.0` and
    `NockedArrow.visible == false`.
14. `blend_resets_after_fire`: after firing, `parameters/blend/blend_amount`
    is `0.0` within `0.0001`.
15. `no_fire_below_threshold`: re-grabbing the string hand at 0.05 m
    separation and releasing produces no new arrow (still exactly 1 in
    group `"arrows"`).
16. `reset_restores_home`: displacing the bow then calling
    `reset_to_home()` restores the origin within 0.001 m.

## Test

`scripts/test_oot_bow_scene.gd` — run:

```
godot --headless --xr-mode off --path . --script res://scripts/test_oot_bow_scene.gd
```

Prints `ALL_PASS` on success or `FAILURES=n` on failure.

## Non-goals

Persistent pickable arrows (ghost `NockedArrow` behavior kept for now, a
later phase adds pickable arrows); replacing the KayKit bow — both bows
coexist.
