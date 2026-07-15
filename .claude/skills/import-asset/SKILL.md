---
name: import-asset
description: Import a 3D asset (gltf/glb) into Trickshot with correct collision shapes — decide shape strategy, generate collision at import time or wire primitives, verify headless. Use when adding new models to assets/, when collision is too loose/boxy, or when the user says "import this model", "add collision", "tighter mesh".
---

# Import a 3D asset with proper collision

## Step 0 — decide the collision strategy

| Object kind | Strategy | Why |
|---|---|---|
| Static scenery, concave (buildings, walls, target stands) | Import-time **Trimesh** (`shape_type 2`) | Exact per-triangle fit; fine for StaticBody3D |
| Static scenery, roughly convex (barrels, rocks, sacks) | Import-time **Simple Convex** (`shape_type 1`) | Much cheaper than trimesh on Quest 2, still tight |
| Static scenery, concave but trimesh too heavy (dense mesh) | Import-time **Decompose Convex** (`shape_type 0`) | V-HACD splits into several convex hulls |
| Grabbable / RigidBody3D (balls, arrows, bow) | Hand-authored primitive (Sphere/Capsule/Box) in the wrapper `.tscn` | **Never trimesh on a moving body** — Godot forbids concave shapes on non-static RigidBody3D; primitives are fastest and Quest 2 physics budget is tight |
| Distant decoration, unreachable (mountains, hills) | No collision at all | Player can't touch it |
| Soft volumes projectiles should pass through slowed (foliage, bushes, curtains) | Wrapper scene: solid core StaticBody3D + Area3D drag zone (`linear_damp_space_override = COMBINE`) — see `scenes/env/tree_a.tscn` / `scripts/tree_drag.gd` | Damping is linear in distance (`dv/dx = −damp`): exit speed = entry − damp × path length, so keep `damp < v_min / zone_diameter` or slow projectiles stall inside. Build shapes in `_ready()` scaled by an export — never scale CollisionShape3D nodes |

Quest 2 rule of thumb: primitives < convex < decompose < trimesh in cost. Pick the cheapest that fits.

## Step 1 — generate collision at import time (headless, no editor)

Edit the asset's `.gltf.import` file. Find the mesh **node name** first (grep `"name"` in the .gltf — use the node entry, e.g. `barrel`), then replace `_subresources={}` with:

```
_subresources={
"nodes": {
"PATH:barrel": {
"generate/physics": true,
"physics/body_type": 0,
"physics/shape_type": 2
}
}
}
```

- `physics/body_type`: `0` Static, `1` Dynamic (RigidBody3D), `2` Area
- `physics/shape_type`: `0` Decompose Convex, `1` Simple Convex, `2` Trimesh (values verified on Godot 4.7)
- One `"PATH:<node_name>"` entry per mesh node that needs collision. Skip nodes that shouldn't collide (foliage cards, decoration).

Then reimport:

```
godot --headless --xr-mode off --path . --import
```

Result (verified): the imported scene gains `MeshInstance3D/StaticBody3D/CollisionShape3D` **inside** the gltf's PackedScene. Trimesh produces `ConcavePolygonShape3D`, convex produces `ConvexPolygonShape3D`.

## Step 2 — verify headless

```
godot --headless --xr-mode off --path . --script res://scripts/dump_scene_tree.gd -- res://assets/kaykit_hex/barrel.gltf
```

**Gotcha:** the Windows Godot exe detaches from the console — run from the Bash tool with stdout redirected to a file (`> /tmp/dump.txt 2>&1; cat /tmp/dump.txt`) or you'll see nothing.

Expected: a `StaticBody3D` + `CollisionShape3D shape=Concave/ConvexPolygonShape3D` under each flagged mesh node.

## Step 3 — remove duplicate hand-placed collision

If the scene using this asset (e.g. `scenes/range_environment.tscn`) already has a hand-placed sibling `StaticBody3D` + `BoxShape3D` for it, delete that pair — otherwise the object collides twice. Import-generated collision inherits the instance's transform automatically, so the old duplicated-transform bookkeeping goes away too.

## Alternative: editor button paths (for manual work)

- **Import-time (same as Step 1, via UI):** FileSystem dock → click the `.gltf` → **Import dock** (tab next to Scene, top-left) → **Advanced...** button at the *bottom* of the Import dock → **Scene** tab → select the mesh node in the left tree → check **Generate > Physics** → set **Body Type** / **Shape Type** → **Reimport**.
- **In-scene:** the **Mesh** menu only appears in the 3D-viewport toolbar when a `MeshInstance3D` is selected. Meshes inside an instanced gltf aren't selectable until you right-click the instance in the Scene dock → **Editable Children**. Then: Mesh menu → **Create Collision Shape...** → choose Trimesh / Single Convex / Simplified Convex / Multiple Convex, sibling placement. Prefer the import-time path — Editable Children bloats the .tscn.
- **Source-asset suffixes** (`-col`, `-convcol`, `-colonly`, `-convcolonly` on node names in the gltf) also work but mean editing third-party asset files — avoid for KayKit packs.

## VR constraints reminder

Renderer stays `gl_compatibility`, physics ticks 72, no realtime shadows. Collision cost is CPU at 72 Hz — audit with the dump script rather than piling on trimesh everywhere.
