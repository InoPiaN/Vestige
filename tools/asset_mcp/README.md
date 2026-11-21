# Vestige local MCP asset bridge (phase 1)

This phase **does not generate images** or invoke a paid API. It provides a safe, local MCP interface to receive a generated PNG, validate it and import it into Godot.

## Setup (macOS, from repository root)

```bash
python3 -m venv .venv-asset
.venv-asset/bin/python -m pip install -r tools/asset_mcp/requirements.txt
```

Configure the Codex MCP client to run this stdio server (adjust the absolute repository path):

```toml
[mcp_servers.vestige_assets]
command = "/ABSOLUTE/PATH/TO/Vestige/.venv-asset/bin/python"
args = ["/ABSOLUTE/PATH/TO/Vestige/tools/asset_mcp/server.py"]
```

In Codex, check that `vestige_assets` exposes:
- `asset_spec(item_id="herb")`: art brief and format requirements
- `import_item_png(item_id="herb", png_base64="...")`: validate and atomically import image
- `asset_status(item_id="herb")`: inspect generated file status

**First asset:** `desktop/assets/items/herb.png` (16×16 RGBA, transparent). The inventory uses the existing procedural herb icon when this file does not exist. Generated artwork is not included in this PR.

## Suggested workflow

1. Ask the image-generation service for a single dark-fantasy moonlit herb with a strong silhouette, transparent background and no text.
2. Review the output for visual quality and convert/correct it to **native 16×16 RGBA pixel art** using a pixel-art editor or approved image-processing step. Do not merely rename a larger image.
3. Encode the PNG bytes as base64 and pass them to the MCP `import_item_png` tool.
4. Call `asset_status` and visually inspect the Godot inventory at nearest-neighbor scaling.
5. Run Godot tests and compare the fallback with the imported asset before committing the PNG.

## Safety and scope

- Only `herb` is allowed; no arbitrary file paths or shell execution through MCP.
- The importer checks PNG signature, chunk CRCs, 16×16 8-bit RGBA layout, pixel decoding, and transparent pixels. Maximum size 256 KiB.
- The import replaces the same allowlisted file only. Review generated content before invoking it.
- MCP server is **local**. No image-generation API keys are requested or stored.
- No changes to item IDs, inventory behavior, save data or gameplay.
- Future phase: optional provider-specific generation adapter, palette/style QA, additional asset IDs, batch processing, audit metadata and regression tests.

## Phase 2 — Optional OpenAI image generation

Install the optional provider dependency:

```bash
.venv-asset/bin/python -m pip install -r tools/asset_mcp/requirements-openai.txt
```

Set `OPENAI_API_KEY` in the **environment of the Codex MCP server process**. A variable exported in a separate shell may not reach an already-running Codex app. Restart Codex after configuration. Do not paste keys into chat, commit them, or put them in the repository. OpenAI API usage is separately billed; ChatGPT subscription does not cover it.

New MCP tools:
- `generate_item_candidate(item_id="herb", approved=False)`: default refuses generation. Only `approved=True` after user approves the billable call invokes OpenAI image generation and writes a local candidate to `.asset-candidates/herb-candidate.png`.
- `import_reviewed_candidate(item_id="herb", approved=False)`: default refuses import. After **visual review**, `approved=True` validates and imports the candidate into `desktop/assets/items/herb.png` without a new generation request.

**Important:** The automatic 16×16 conversion uses a small fixed palette and is only a prototype. It may lose fine details or produce a poor silhouette; manual pixel-art cleanup is recommended. The server does not automatically import or commit candidate art.

No API calls occur during tests. Run:

```bash
.venv-asset/bin/python -m unittest discover -s tools/asset_mcp -p 'test_*.py'
```

Generation uses `gpt-image-1` with transparent PNG output. Model availability, request parameters, pricing, and organization verification may change; validate them in your OpenAI API account before approving a paid call.
