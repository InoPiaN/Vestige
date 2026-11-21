# Chapter I — Kael conversation slice

Branch: `feature/chapter1-kael-dialogue` based on `feature/chapter1-story-foundation`.

## Implemented
- Kael NPC at (17,14) using the existing NPC discovery, server-side session validation, button UI and pixel-character rendering. No new collision rectangle was created.
- Physical clue `kael_token` at (26,14), visualized as **낡은 표식**. It uses the current E-key/N-key experience, physical proximity checks, wolf encounter gate, per-life records, provenance metadata and save.
- Logical link `kael_token → E06`. The item alone **does not** establish who operated the machine, murder, or Irene's fate.
- Kael options: ask about Irene (always), chapel traces (requires `chapel_traces`), and metal token (requires `kael_token`). Invalid NPC, range, missing evidence and inactive-session requests are rejected by existing server validation.
- Upon first greeting, record encounter; on showing the token, store one-time `kael_token_owner_admitted` event in personal chapter state.
- Bran/Sera continue to support the original rumor/evidence choices; token-specific testimony does not assert culpability.
- Existing world movement, building collision, crafting, combat and world save-version policies remain unchanged.

## Not implemented / intentionally deferred
- No completed `E07/E08/E09/E10/E13` chain, no definitive operator identification, no Kael confession or chapter ending.
- No underground chapel, expanded inference UI, new character assets, or route changes.
- The exact identity of the last speaker/echo and Irene's final intent remain unresolved.
- Treat token ownership as a character statement; the notebook's physical observation remains limited to the observed metal mark.

## Tests
Run from repository root on the Kael branch:

```bash
godot --headless --path desktop --script res://tests/test_kael_dialogue.gd
godot --headless --path desktop --script res://tests/test_chapter1_story.gd
godot --headless --path desktop --script res://tests/test_dialogue.gd
godot --headless --path desktop --script res://tests/test_investigation.gd
godot --headless --path desktop --script res://tests/test_investigation_ui.gd
```

The new Kael test checks reachability, proximity, the server-owned active dialogue session, token gating, one-time discovery, the limited inference, per-life isolation, and round-trip save/load.

## Manual play path
1. On a separate QA world, visit Kael at (17,14). The E-key opens his dialogue. Ask about Irene; no guilt is announced.
2. Defeat the wolf near the chapel. At (26,14), E records the metal token. Inspect N to verify uncertain interpretation and provenance.
3. Return to Kael and choose '발견한 금속 표식을 보여준다'. He admits ownership/visiting, not operating the machine. Repeat it and reload; the personal event stays unique.
4. Verify Bran/Sera, equipment, forge entrances, walking around the Irene house, and save/reconnect.

## Notes
Current developer setup has Godot 4.7.2. Previous prototype documentation targeted 4.5.1. The code has not been run in this assistant environment; do not treat these changes as passing until checked locally.

All gameplay assertions about the cause of Irene's disappearance are withheld until further evidence and validation are implemented.
