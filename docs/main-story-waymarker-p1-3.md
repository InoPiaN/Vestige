# VESTIGE P1-3 · ACT I waymarker runtime interaction

Base: `feature/main-story-act1-foundation-v1`.

## Included
- Fixed non-blocking sign rendered in the existing village near tile (3,16), chosen to avoid current building, spawn (9,9), and travel gate (29,9). This placement is provisional until in-game QA.
- E key routes to the fixed `main.act1.waymarker_evidence` target when in range; all other existing investigation interactions remain in place.
- On single player or server, interaction authorization checks actor, current life, target ID, region, alive/offline status, and range; it does not accept client event IDs or coordinates as evidence.
- Per-life `main_story` event and knowledge are recorded once; provenance-bearing observation goes to `main_story.evidence` rather than the Iren/legacy `story.evidence`.
- N key notebook includes acquired main-story evidence, clearly separating observed facts from inference.
- Optional main story state is validated by the existing world save validator before save/load repair, without bumping version 23; older story-free saves remain supported.
- Existing network snapshot redaction from previous branch remains active.

## Not included
- Conditional Sera conversation is still a data template, not yet wired into live T dialogue.
- Second clue / supply ledger comparison, longer 5-act scenes, and actual story transitions are not implemented.
- Same-life/death-and-successor behavior and official naming of the village are unresolved; this vertical slice only changes a living player's personal state.
- No changes to aging/death, server world rules, client identity, or existing Iren dialogue.
- Do not merge without local Godot and ENet regression.

## Mac test commands
```bash
git fetch origin
git switch feature/main-story-waymarker-interaction-v1
godot --headless --path desktop --script res://tests/test_main_story_contract.gd
godot --headless --path desktop --script res://tests/test_main_story_director.gd
godot --headless --path desktop --script res://tests/test_main_story_act1_foundation.gd
godot --headless --path desktop --script res://tests/test_main_story_waymarker.gd
```

After they pass, visually verify in a separate QA save: stand near (3,16), press E, view N, repeat E, save/restart, verify persistent observation. Check old chapter1 evidence/N UI, spawn walkability, and two-client privacy. The connected GitHub environment does not execute the Godot runtime; no runtime test result has been claimed.
