import sys
import unittest
from pathlib import Path


TOOL_DIRECTORY = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOL_DIRECTORY))

import image_input_probe


class AspectRatioTests(unittest.TestCase):
    def test_parse_ratio_normalizes_values(self):
        ratio = image_input_probe.parse_ratio("32:18")

        self.assertEqual(ratio.label, "16:9")
        self.assertEqual((ratio.width, ratio.height), (16, 9))

    def test_landscape_dimensions_use_long_edge_as_width(self):
        ratio = image_input_probe.parse_ratio("16:9")

        self.assertEqual(ratio.dimensions(1920), (1920, 1080))

    def test_portrait_dimensions_use_long_edge_as_height(self):
        ratio = image_input_probe.parse_ratio("9:16")

        self.assertEqual(ratio.dimensions(1920), (1080, 1920))


class LongEdgeTests(unittest.TestCase):
    def test_growth_includes_maximum_cap(self):
        sizes = image_input_probe.build_long_edges(512, 12_288, 2)

        self.assertEqual(sizes, [512, 1024, 2048, 4096, 8192, 12_288])

    def test_explicit_sizes_preserve_order_and_values(self):
        sizes = image_input_probe.build_long_edges(
            512,
            8192,
            2,
            explicit_sizes=[1024, 768, 2048],
        )

        self.assertEqual(sizes, [1024, 768, 2048])


class JPEGQualityTests(unittest.TestCase):
    def test_valid_quality(self):
        self.assertEqual(image_input_probe.parse_jpeg_quality("80"), 80)

    def test_invalid_quality(self):
        with self.assertRaises(Exception):
            image_input_probe.parse_jpeg_quality("101")


class ExpectedTermsTests(unittest.TestCase):
    def test_matching_is_case_insensitive(self):
        missing = image_input_probe.missing_expected_terms(
            "The colors are Blue and Gold.",
            ["blue", "gold"],
        )

        self.assertEqual(missing, [])

    def test_missing_terms_are_returned(self):
        missing = image_input_probe.missing_expected_terms(
            "The colors are dark green and black.",
            ["blue", "gold"],
        )

        self.assertEqual(missing, ["blue", "gold"])


class EstimatedBufferTests(unittest.TestCase):
    def test_square_boundary_matches_observed_behavior(self):
        _, last_success_bytes = image_input_probe.estimated_bgra_buffer(23_168, 23_168)
        _, first_failure_bytes = image_input_probe.estimated_bgra_buffer(23_169, 23_169)

        self.assertLess(last_success_bytes, image_input_probe.TWO_GIB_BYTES)
        self.assertGreaterEqual(first_failure_bytes, image_input_probe.TWO_GIB_BYTES)

    def test_landscape_boundary_matches_observed_behavior(self):
        _, last_success_bytes = image_input_probe.estimated_bgra_buffer(30_892, 17_377)
        _, first_failure_bytes = image_input_probe.estimated_bgra_buffer(30_893, 17_377)

        self.assertLess(last_success_bytes, image_input_probe.TWO_GIB_BYTES)
        self.assertGreaterEqual(first_failure_bytes, image_input_probe.TWO_GIB_BYTES)


if __name__ == "__main__":
    unittest.main()
