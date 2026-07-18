---
name: analyze-screenshot
description: Break down a Trickshot VR screenshot into structured 3D-space debug info and map it back to code. Reads the on-screen debug HUD (frame/camera/tracked transforms/bow state) and wireframe boxes, cross-references the scene tree + scripts, and reports world-space deltas. Use when the user feeds a screenshot to debug placement/alignment (bow, arrow, targets), says "here's a screenshot", "why does this look wrong", "map this back to the code", or captures a shot with the in-game screenshot button.
---

# Analyze a Trickshot debug screenshot

The game renders a **debug overlay** (HUD text + wireframe boxes) driven by the
`DEBUG` env var (see `scripts/debug_overlay.gd`, `scripts/debug_hud_format.gd`,
`scripts/debug_config.gd`). Your job: turn a screenshot into a structured,
code-mapped diagnosis. Do NOT eyeball geometry and guess — read the overlay,
then confront it with the code.

## Step 0 — is the overlay present?

Look at a corner for HUD text of this exact shape (from `debug_hud_format.gd`):

```
[f42 14:57:49]
CAM pos(0.35, 1.60, 0.80) dir(0.00, 0.00, -1.00)
BOW draw=0.75 loaded=true nock=0.37
oot-bow-nocked pos(1.00, 2.00, 3.00) rot(0.00, 90.00, 0.00)
arrow pos(-1.50, 0.25, 4.00) rot(10.00, 0.00, -5.00)
```

- **No HUD** → tell the user to relaunch with `DEBUG=true` (or `DEBUG=<ids>`).
  Without it you are guessing pixels. Say so; don't fake precision.
- **HUD present** → transcribe every line verbatim into your working notes.
  These numbers are ground truth for the exact frame shown.

**Prefer the JSON sidecar over the pixels.** The in-game screenshot button
(stick press) writes `debug/screenshots/shot_<frame>.png` AND
`shot_<frame>.json`. The `.json` is the authoritative debug state (camera,
tracked transforms as `{x,y,z}`, bow `{draw,loaded,nock}`, `fps`) for that exact
frame — read it directly instead of OCRing the HUD. Match a user-supplied image
to its sidecar by the `shot_<frame>` name or the wall-clock. The `.png` is a mono
mirror from the headset viewpoint (shows the wireframe boxes; the 2D HUD text is
NOT baked into it — that lives in the sidecar).

## Step 1 — parse the HUD into a state table

| Field                     | Meaning                                                       | Code source                                     |
| ------------------------- | ------------------------------------------------------------- | ----------------------------------------------- |
| `[f<N> <clock>]`          | frame counter + wall clock                                    | correlates to the saved PNG name `shot_<N>.png` |
| `CAM pos / dir`           | camera world position + look vector                           | reconstruct the viewpoint                       |
| `BOW draw=/loaded=/nock=` | `_draw`, `_loaded`, nock pull offset                          | `bow_base.gd`, `oot_bow.gd:_update_draw_visual` |
| `<id> pos / rot`          | each tracked node's world transform (rot = euler **degrees**) | the node whose `debug_id` meta == `<id>`        |

## Step 2 — match wireframe boxes to ids

Each tracked object is drawn as a wireframe AABB (`debug_wire_geometry.gd`).
The box shows the object's **visual bounds** in world space. Use it to see:

- **Offset**: box center vs where the mesh visually sits → mesh pivot is off.
- **Size/orientation**: a box that doesn't hug the mesh → wrong scale/basis
  (the KayKit arrow vs OoT bow mismatch lives here).
- **Overlap/gap** between the arrow box and the bow riser → nock contact error.

## Step 3 — confront the code

For each id in the HUD, open the node's script/scene and compare the HUD numbers
to what the code _intends_:

- Nocked arrow: `oot_bow.gd` `NOCK_PULL`, `NOCK_TAIL_OFFSET`, `_nock_rest`, and
  the mesh basis in `scenes/oot_arrow.tscn` (the `Mesh` node transform). A canted
  shaft or tail-off-string comes from these constants vs the observed `pos/rot`.
- Report the **delta**: "HUD says arrow rot(…,…,…); code authored rest basis maps
  +X→tip, so expected …; difference ⇒ adjust <constant/transform>."

## Step 4 — output format

Give the user, in this order:

1. **Transcribed HUD** (so they can confirm you read it right).
2. **Per-object finding**: id → observed world transform → what code sets it →
   the discrepancy, as a concrete number, not a vibe.
3. **Proposed change**: the exact file + constant/transform to edit, and which
   direction/magnitude. If it needs another screenshot to confirm, say which
   angle/state to capture next.

## Rules

- Numbers over adjectives. "0.37 m too far back along -X" beats "looks off".
- If the HUD and the wireframe disagree with each other, flag it — the overlay
  itself may be mis-wired (a `debug_overlay.gd` bug), not the bow.
- Never invent a transform the HUD didn't show. Missing field → ask for a shot
  with that object tracked (add its `debug_id` to `DEBUG`).
