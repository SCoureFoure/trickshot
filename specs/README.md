# Specs

This directory holds one `<feature>.spec.md` per system, paired 1:1 with a
`scripts/test_*.gd` headless suite. Each spec follows the same section
layout:

- **Requirement** — what the system must do, in plain language
- **Design decisions (pinned)** — choices already made, not up for reopening
- **Acceptance criteria** — concrete `input → expected` pairs
- **Test** — the headless `test_*.gd` suite that checks the acceptance criteria
- **Non-goals** — explicitly out of scope

Acceptance criteria are the doer contract when work is dispatched via
Warboss — a doer implements exactly what the acceptance criteria state, no
more.

## Current specs

- `trickshot_playground.spec.md` — game design (not fully machine-testable)
- `throw_release_velocity.spec.md` ↔ `scripts/test_throw_sampler.gd`
- `ball_types.spec.md` ↔ `scripts/test_ball_types.gd`
- `spawn_budget.spec.md` ↔ `scripts/test_spawn_budget.gd`
- `bow_draw.spec.md` ↔ `scripts/test_bow_draw.gd`
- `arrow.spec.md` ↔ `scripts/test_arrow_scene.gd`
- `bow.spec.md` ↔ `scripts/test_bow_scene.gd`
- `oot_arrow.spec.md` ↔ `scripts/test_oot_arrow_scene.gd`
- `oot_bow.spec.md` ↔ `scripts/test_oot_bow_scene.gd`
- `archery_target.spec.md` ↔ `scripts/test_archery_target_scene.gd`
- `range_environment.spec.md` ↔ `scripts/test_range_environment_scene.gd`
