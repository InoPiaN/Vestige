"""Optional OpenAI generation adapter. Never call without explicit per-request approval.

Generation produces a *candidate* in an ignored local directory, not a game asset.
A human must review the pixel preview before importing it into Godot.
"""
from __future__ import annotations

import base64
from io import BytesIO
import json
import os
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
CANDIDATES = ROOT / ".asset-candidates"
MODEL = "gpt-image-1"
PROMPT = (
    "Create a SINGLE centered moonlit medicinal herb item icon for a dark fantasy "
    "pixel art RPG. Crisp readable silhouette, muted sage green leaves, pale "
    "moonlit tip, no text, no frame, no shadow, transparent background. "
    "Designed to be recognizable at 16x16 pixels. No extra objects."
)
PALETTE = [
    (0, 0, 0, 0),
    (36, 54, 48, 255),
    (62, 90, 74, 255),
    (93, 130, 99, 255),
    (138, 184, 142, 255),
    (189, 208, 163, 255),
    (219, 228, 190, 255),
    (236, 232, 200, 255),
]


def pixelate_candidate(payload: bytes) -> bytes:
    """Convert image to strict 16x16 RGBA using a fixed palette.

    Conversion is a *candidate*, not a guarantee of aesthetically good pixel art.
    """
    with Image.open(BytesIO(payload)) as source:
        source.load()
        image = source.convert("RGBA")
    image.thumbnail((16, 16), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    canvas.alpha_composite(image, ((16 - image.width) // 2, (16 - image.height) // 2))
    pixels = canvas.load()
    for y in range(16):
        for x in range(16):
            r, g, b, a = pixels[x, y]
            if a < 128:
                pixels[x, y] = (0, 0, 0, 0)
            else:
                pixels[x, y] = min(PALETTE[1:], key=lambda p: (r-p[0])**2 + (g-p[1])**2 + (b-p[2])**2)
    buffer = BytesIO()
    canvas.save(buffer, format="PNG")
    return buffer.getvalue()


def generate_candidate(item_id: str, approved: bool = False) -> dict:
    if item_id != "herb":
        return {"ok": False, "error": "unsupported item_id"}
    if not approved:
        return {"ok": False, "error": "Explicit approval required: generation may incur API charges"}
    if not os.getenv("OPENAI_API_KEY"):
        return {"ok": False, "error": "OPENAI_API_KEY is not configured"}
    try:
        from openai import OpenAI
    except ImportError:
        return {"ok": False, "error": "Install optional dependency: pip install openai"}
    try:
        # Provider call: this is the only billable operation in the pipeline.
        response = OpenAI().images.generate(
            model=MODEL,
            prompt=PROMPT,
            size="1024x1024",
            background="transparent",
            output_format="png",
            n=1,
        )
        data = response.data[0].b64_json
        if not data:
            return {"ok": False, "error": "Provider returned no base64 image"}
        original = base64.b64decode(data, validate=True)
        if len(original) > 15 * 1024 * 1024:
            return {"ok": False, "error": "Provider image exceeds size limit"}
        pixel_png = pixelate_candidate(original)
        # Reuse the strict project PNG validator without writing to game assets.
        from server import check_png
        check_png(pixel_png)
        CANDIDATES.mkdir(parents=True, exist_ok=True)
        target = CANDIDATES / (item_id + "-candidate.png")
        target.write_bytes(pixel_png)
        return {
            "ok": True,
            "candidate": str(target.relative_to(ROOT)),
            "next_step": "Review candidate at nearest-neighbor zoom; only then call import_item_png",
            "cost_incurred": True,
        }
    except Exception as exc:
        # Do not return request details or credentials in provider error messages.
        return {"ok": False, "error": type(exc).__name__, "cost_may_have_been_incurred": True}
