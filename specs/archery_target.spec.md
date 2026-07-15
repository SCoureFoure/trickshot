# Spec: Archery Target scene

## Requirement

Standing archery target using the KayKit hex-pack model whose painted disc
scores hits via the shared ring logic. Player shoots arrows at the target face
to earn points based on ring distance.

## Design decisions (pinned)

- Reuses `scripts/target.gd` verbatim for all hit/scoring logic.
- Reuses `Scoring.RING_RADII` ([0.15, 0.30, 0.45] m) for ring boundaries.
- Mesh scale 6.5 so disc radius 0.455 m ≈ outer ring 0.45 m; scoring maps 1:1
  onto the painted disc.
- Scene root origin at the stand base (placement-friendly — drop at ground
  level in main.tscn); the disc center is pinned by the exported
  `bull_center = (-0.005, 0.613, -0.171)` on the scene root, and `target.gd`
  scores ring distance relative to `bull_center` (old `scenes/target.tscn`
  keeps the default ZERO).
- Hit sound is `res://assets/audio/arrow_wood_impact.mp3` (attribution in
  `assets/audio/CREDITS.md`) assigned in the scene; `target.gd`'s procedural
  beep remains as a fallback for scenes that assign no stream.
- Empty `Rings` node: no flash visual (target.gd `_flash()` iterates children).
- Backing StaticBody3D so arrows stick in the board instead of passing through.
- Backing box covers the whole visible mesh (1.6 w x 2.0 h), is >= 0.5 thick
  (anti-tunnel: no CCD on balls), and presents its front plane at z ~= 0 so
  projectiles cross the scoring Face area (z 0..0.08) before contact.

## Acceptance criteria

1. `scene_loads` — `scenes/archery_target.tscn` is a valid PackedScene that
   instantiates and can be added to the scene tree.
2. `script_is_target_gd` — Target's script resource_path is exactly
   `"res://scripts/target.gd"`.
3. `has_kaykit_mesh` — Target has a child node "Mesh" (the instanced KayKit
   model).
4. `has_backing_body` — Target has a child "Backing" that is a StaticBody3D.
   `backing_covers_visual` — its BoxShape3D is >= 1.5 x 1.8 x 0.4.
   `backing_front_at_face` — backing front plane sits at |z| <= 0.05.
5. `face_area_monitoring` — Target has a child "Face" that is an Area3D with
   `monitoring == true`.
6. `hit_sound_ready` — Target has a child "HitSound" that is an
   AudioStreamPlayer3D, `stream != null`, and `stream is AudioStreamMP3`
   (scene-assigned mp3, not the procedural beep).
7. `bullseye_scores_25` — `target.points_for_local_hit(BULL) == 25`, where
   `BULL := Vector3(-0.005, 0.613, -0.171)`.
8. `mid_ring_scores_10` — `target.points_for_local_hit(BULL + Vector3(0.2, 0, 0)) == 10`.
9. `outer_ring_scores_5` — `target.points_for_local_hit(BULL + Vector3(0, 0.4, 0)) == 5`.
10. `miss_scores_0` — `target.points_for_local_hit(BULL + Vector3(0.5, 0, 0)) == 0`.
    `origin_is_not_bull` — `target.points_for_local_hit(Vector3.ZERO) == 0`
    (kills any regression back to origin-based scoring).
    `bull_center_exported` — `target.bull_center` equals `BULL` within 0.001
    per component.
11. `arrow_hit_scores_bullseye` — A RigidBody3D in the "arrows" group entering
    the Face area at the target's `to_global(BULL)` emits `target_hit` with
    points=25.
12. `cooldown_blocks_double_hit` — A second hit from the same arrow within 1.0 s
    does not emit (HIT_COOLDOWN prevents scoring the same arrow twice).
13. `non_arrow_ignored` — A RigidBody3D *not* in "arrows" or "balls" groups
    entering the Face area does not emit `target_hit`.

## Test

`scripts/test_archery_target_scene.gd` — run:

```
godot --headless --xr-mode off --path . --script res://scripts/test_archery_target_scene.gd
```

Prints `ALL_PASS` on success or `FAILURES=n` on failure.

## Non-goals

- Replacing `scenes/target.tscn` (the original target remains for its own suite).
- Per-ring painted-disc color flash animations.
- Arrow retrieval or pickup mechanics.
