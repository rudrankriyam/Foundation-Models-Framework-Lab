import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


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


class MainLoopTests(unittest.TestCase):
    def test_pixel_cap_skip_does_not_abort_non_monotonic_explicit_sizes(self):
        successful_record = {
            "ratio": "1:1",
            "width": 10,
            "height": 10,
            "megapixels": 0.0,
            "bytes": 1,
            "response_seconds": 0.0,
            "response": "ok",
            "success": True,
        }

        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "source.jpg"
            source.touch()
            output_directory = root / "output"

            with (
                mock.patch.object(
                    image_input_probe,
                    "run_command",
                    return_value=image_input_probe.CommandResult(0, "", "", 0),
                ),
                mock.patch.object(
                    image_input_probe,
                    "resolve_executable",
                    side_effect=lambda value: value,
                ),
                mock.patch.object(
                    image_input_probe,
                    "macos_version_value",
                    return_value="test",
                ),
                mock.patch.object(
                    image_input_probe,
                    "generate_variant",
                    return_value=image_input_probe.CommandResult(0, "", "", 0),
                ) as generate_variant,
                mock.patch.object(
                    image_input_probe,
                    "image_properties",
                    return_value={
                        "width": 10,
                        "height": 10,
                        "format": "jpeg",
                        "bytes": 1,
                    },
                ),
                mock.patch.object(
                    image_input_probe,
                    "test_image",
                    return_value=successful_record,
                ) as test_image,
            ):
                exit_code = image_input_probe.main(
                    [
                        str(source),
                        "--skip-source",
                        "--ratios",
                        "1:1",
                        "--sizes",
                        "20,10",
                        "--max-pixels",
                        "150",
                        "--fm-path",
                        "fm",
                        "--sips-path",
                        "sips",
                        "--output-dir",
                        str(output_directory),
                    ]
                )

        self.assertEqual(exit_code, 0)
        generate_variant.assert_called_once()
        self.assertEqual(generate_variant.call_args.kwargs["width"], 10)
        self.assertEqual(generate_variant.call_args.kwargs["height"], 10)
        self.assertEqual(test_image.call_args.kwargs["long_edge"], 10)


if __name__ == "__main__":
    unittest.main()
