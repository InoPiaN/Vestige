# VESTIGE main-story foundation · Phase P0-2

Date: 2026-11-24. Source: MAIN_STORY_CANON v2.8 / Narrative Draft v3.0 / architecture draft v3.1.

## Baseline and isolation

- Start from `main`, not `feature/ash-village-investigation`: the latter diverged substantially.
- Godot project root: `desktop/`. Main entry point: `desktop/main.gd`.
- Existing `story.chapter1` and its Chapter I / Iren investigation are **legacy content**, NOT the new five-act main story. Do not rename or rewrite them.
- Existing world save format is version 23. This change does not bump version or modify save read/write paths.
- New optional per-person namespace: `person.main_story`. No mutation occurs unless `MainStoryContract.ensure_person(person)` is explicitly called.
- The new contract checks data structure only. It is NOT yet wired into `world_store.gd` or network commands; do not claim runtime enforcement.

## Identity, facts and authority

- Canonical pre-accident identity belongs in read-only main-story content; present chosen name remains in the existing `person.name` field.
- Never duplicate or overwrite the immutable historical name with the player's chosen name.
- Personal `main_story.knowledge` flags encode what the character verified, not whether the world fact is true.
- Personal `main_story.decisions` and `relationships` encode current choices, not retroactive changes to the accident.
- A player must be able to stabilize the Act V facility independently of Arden's decision.
- The shared-world server must authorize any eventual main-story state changes; a client must not submit arbitrary knowledge, event completion or facility state.

## Known scenario / current prototype conflicts to resolve before scene integration

1. Existing `chapter1` is an Iren investigation with its own Kael/Sera dialogue; the newly confirmed main story begins with the expedition waymarker. Matching names must not imply matching timeline/role or overwrite their data.
2. Existing game implements aging, death, inherited belongings and new lives. The main story promises same-character single-to-multiplayer continuity. Define how a character dying before story completion is handled BEFORE wiring that progression.
3. Older notes use 잿빛 마을 while the current prototype refers to 잿불 마을. This naming correspondence is not canonically settled.
4. Accident-to-opening interval (~2 years), Rian's death circumstances and historical name literal remain proposals/unresolved. Do not fill these in through code.
5. Previously shipped save structures and investigation/ENet flows must continue to pass regression tests.

## First incremental vertical slice (not implemented here)

1. Read-only inspect target `main.act1.old_waymarker`.
2. Server-authoritative interaction validates player life/position and target distance.
3. Add a provenance-bearing main-story evidence record without touching `story.chapter1.evidence`.
4. Set a personal fact flag once and enable Sera's corresponding main-story line.
5. Save/reload/reconnect without duplicate rewards, crossed player state or changes to old investigations.

## Tests added

```bash
godot --headless --path desktop --script res://tests/test_main_story_contract.gd
```

Tests check legacy preservation, idempotent opt-in initialization, successful JSON round trip, invalid type/act rejection and no repair of corrupted state.

**Execution status:** not run in this change; the connected GitHub environment cannot execute local Godot. Keep the branch unmerged until headless testing and existing regression checks pass.
