"""Vestige local asset MCP bridge. Install: pip install -r tools/asset_mcp/requirements.txt

The bridge accepts generated PNG bytes; it does not call a paid image API.
Only allowlisted item IDs are writable. No credentials are stored.
"""
from __future__ import annotations

import base64
import binascii
import json
import os
from pathlib import Path
import struct
import tempfile

from mcp.server.fastmcp import FastMCP

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "desktop" / "assets" / "items"
ALLOWED = {"herb"}
PNG_SIG = b"\x89PNG\r\n\x1a\n"
MAX_PNG_BYTES = 256 * 1024

mcp = FastMCP("vestige-asset-pipeline")


def check_png(payload: bytes) -> dict:
    if len(payload) > MAX_PNG_BYTES or len(payload) < 45:
        raise ValueError("PNG byte length out of bounds")
    if not payload.startswith(PNG_SIG):
        raise ValueError("Not a PNG")
    offset = 8
    ihdr = None
    has_iend = False
    while offset + 12 <= len(payload):
        length = struct.unpack(">I", payload[offset:offset + 4])[0]
        if length > MAX_PNG_BYTES or offset + 12 + length > len(payload):
            raise ValueError("Invalid PNG chunk length")
        kind = payload[offset + 4:offset + 8]
        data = payload[offset + 8:offset + 8 + length]
        crc = struct.unpack(">I", payload[offset + 8 + length:offset + 12 + length])[0]
        if (binascii.crc32(kind + data) & 0xFFFFFFFF) != crc:
            raise ValueError("PNG CRC mismatch")
        if offset == 8:
            if kind != b"IHDR" or length != 13:
                raise ValueError("Missing PNG IHDR")
            width, height, depth, color, compression, filtering, interlace = struct.unpack(">IIBBBBB", data)
            if (width, height, depth, color, compression, filtering, interlace) != (16, 16, 8, 6, 0, 0, 0):
                raise ValueError("Expected non-interlaced 16x16 RGBA PNG (8-bit)")
            ihdr = {"width": width, "height": height, "color": "RGBA"}
        offset += 12 + length
        if kind == b"IEND":
            if length != 0 or offset != len(payload):
                raise ValueError("Invalid PNG end")
            has_iend = True
            break
    if ihdr is None or not has_iend:
        raise ValueError("Incomplete PNG")
    # Decode pixels as well: structurally valid PNG can contain corrupt IDAT.
    try:
        from PIL import Image
        from io import BytesIO
        with Image.open(BytesIO(payload)) as img:
            img.load()
            if img.mode != "RGBA" or img.size != (16, 16):
                raise ValueError("Unexpected decoded pixel format")
            if img.getchannel("A").getextrema() == (255, 255):
                raise ValueError("Background is opaque; transparent pixels required")
    except ImportError as exc:
        raise RuntimeError("Pillow is required for pixel validation") from exc
    return ihdr


@mcp.tool()
def asset_spec(item_id: str = "herb") -> str:
    """Return the art brief and acceptance criteria for a supported item."""
    if item_id not in ALLOWED:
        return json.dumps({"error": "unsupported item_id"}, ensure_ascii=False)
    return json.dumps({
        "item_id": item_id,
        "name": "달빛 약초",
        "brief": "single moonlit medicinal herb, readable silhouette, dark-fantasy muted sage leaves and pale moonlit tip, 16x16 true pixel art",
        "requirements": ["16x16 PNG", "RGBA 8-bit", "transparent background", "no text", "no border", "no anti-aliased blur"],
        "output": "desktop/assets/items/herb.png",
        "note": "Generate externally, convert/review at native resolution, then call import_item_png."
    }, ensure_ascii=False)


@mcp.tool()
def import_item_png(item_id: str, png_base64: str) -> str:
    """Validate and write a generated 16x16 RGBA PNG to the allowlisted Godot asset path."""
    if item_id not in ALLOWED:
        return json.dumps({"ok": False, "error": "unsupported item_id"})
    try:
        payload = base64.b64decode(png_base64, validate=True)
        metadata = check_png(payload)
        ASSETS.mkdir(parents=True, exist_ok=True)
        target = ASSETS / (item_id + ".png")
        fd, tmp = tempfile.mkstemp(prefix=".asset-", suffix=".png", dir=ASSETS)
        try:
            with os.fdopen(fd, "wb") as f:
                f.write(payload)
            os.replace(tmp, target)
        finally:
            if os.path.exists(tmp):
                os.unlink(tmp)
        return json.dumps({"ok": True, "path": str(target.relative_to(ROOT)), **metadata})
    except (ValueError, binascii.Error, OSError, RuntimeError) as exc:
        return json.dumps({"ok": False, "error": str(exc)})


@mcp.tool()
def asset_status(item_id: str = "herb") -> str:
    """Check whether an allowlisted asset exists and passes validation."""
    if item_id not in ALLOWED:
        return json.dumps({"ok": False, "error": "unsupported item_id"})
    target = ASSETS / (item_id + ".png")
    if not target.exists():
        return json.dumps({"ok": True, "present": False, "fallback": "procedural icon"})
    try:
        return json.dumps({"ok": True, "present": True, **check_png(target.read_bytes())})
    except (ValueError, RuntimeError) as exc:
        return json.dumps({"ok": False, "present": True, "error": str(exc)})


if __name__ == "__main__":
    mcp.run(transport="stdio")
