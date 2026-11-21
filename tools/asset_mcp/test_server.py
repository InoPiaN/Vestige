"""Run: .venv-asset/bin/python -m unittest discover -s tools/asset_mcp -p 'test_*.py'"""
import base64
from io import BytesIO
import unittest

from PIL import Image

from server import check_png


class AssetValidationTests(unittest.TestCase):
    def make_png(self, transparent=True):
        image = Image.new("RGBA", (16, 16), (0, 0, 0, 0) if transparent else (10, 20, 30, 255))
        image.putpixel((7, 7), (90, 170, 110, 255))
        buffer = BytesIO()
        image.save(buffer, format="PNG")
        return buffer.getvalue()

    def test_valid_transparent_rgba(self):
        self.assertEqual(check_png(self.make_png())["width"], 16)

    def test_reject_opaque(self):
        with self.assertRaises(ValueError):
            check_png(self.make_png(False))

    def test_reject_wrong_dimensions(self):
        buffer = BytesIO()
        Image.new("RGBA", (32, 32), (0, 0, 0, 0)).save(buffer, format="PNG")
        with self.assertRaises(ValueError):
            check_png(buffer.getvalue())

    def test_reject_corrupt_crc(self):
        payload = bytearray(self.make_png())
        payload[20] ^= 1
        with self.assertRaises(ValueError):
            check_png(bytes(payload))

    def test_reject_non_png(self):
        with self.assertRaises(ValueError):
            check_png(b"not a png")


if __name__ == "__main__":
    unittest.main()
