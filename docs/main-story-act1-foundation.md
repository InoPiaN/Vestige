# Main story ACT I foundation (P1-2 preparatory increment)

Base: `feature/main-story-director-v1`.

## Added
- `story/main_story_act1_content.gd`: isolated ACT I event definition, waymarker evidence text with fact/inference separation, Sera's conditional dialogue text. No waypoint coordinates are assigned yet.
- `story/main_story_snapshot.gd`: removes non-owning participants' `main_story` data from a copied network snapshot.
- `main.gd`: applies that helper before per-player ID hashing and snapshot transmission.
- `tests/test_main_story_act1_foundation.gd`: verifies event deduplication, legacy data preservation, dialogue state and network privacy.

## Intentionally NOT integrated yet
- The waymarker is NOT placed in the map and cannot be interacted with via E.
- The event is NOT invoked from existing `interact()` or network `command()`; do not accept arbitrary client event IDs.
- The evidence template is NOT yet collected or stored as discovered evidence.
- Sera's main-story dialogue is NOT yet exposed in the current UI.
- The chapter1/Iren investigation is untouched; names and timelines must not be conflated.
- No shared-world/cross-life story rules were changed.

## Before runtime activation
1. Verify actual map placement, passable spawn areas and collision around the waymarker.
2. Decide same-life story progression with existing aging/death and successor mechanics.
3. Define an authoritative server side fixed-target interaction with distance, room, life ID and event guards. Do not expose `StoryDirector.apply_event()` as a client RPC.
4. Add provenance-bearing personal evidence storage and validate it on save load.
5. Add UI to view main-story evidence and Sera's conditional dialogue without replacing legacy N/T controls.
6. Run existing world, investigation, save and ENet regression tests.

## Verification
```bash
git fetch origin
git switch feature/main-story-act1-foundation-v1
godot --headless --path desktop --script res://tests/test_main_story_contract.gd
godot --headless --path desktop --script res://tests/test_main_story_director.gd
godot --headless --path desktop --script res://tests/test_main_story_act1_foundation.gd
```
No local Godot execution was performed when creating these files. Verify on macOS before merging.
