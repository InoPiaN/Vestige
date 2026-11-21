"""Offline tests: no API requests or paid operations."""
import unittest
from io import BytesIO

from PIL import Image

from generator import generate_candidate, pixelate_candidate
from server import check_png


class CandidateTests(unittest.TestCase):
    def test_requires_explicit_approval(self):
        result = generate_candidate("herb", approved=False)
        self.assertFalse(result["ok"])
        self.assertIn("approval", result["error"].lower())

    def test_unknown_item_rejected(self):
        self.assertFalse(generate_candidate("other", approved=True)["ok"])

    def test_pixelate_to_valid_rgba(self):
        image = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
        for x in range(20, 44):
            for y in range(20, 44):
                image.putpixel((x, y), (70, 160, 90, 255))
        buffer = BytesIO()
        image.save(buffer, format="PNG")
        result = pixelate_candidate(buffer.getvalue())
        self.assertEqual(check_png(result)["width"], 16)

    def test_no_background_stays_transparent(self):
        image = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
        buffer = BytesIO()
        image.save(buffer, format="PNG")
        converted = Image.open(BytesIO(pixelate_candidate(buffer.getvalue())))
        self.assertEqual(converted.getpixel((0, 0))[3], 0)


if __name__ == "__main__":
    unittest.main()
