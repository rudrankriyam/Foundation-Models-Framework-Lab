#!/usr/bin/env python3
"""Empirically probe Apple Foundation Models image-input limits."""

from __future__ import annotations

import argparse
import json
import math
import os
import platform
import re
import shutil
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Sequence


DEFAULT_RATIOS = ("1:1", "16:9", "9:16", "4:3", "3:4", "3:2", "2:3")
DEFAULT_PROMPT = "Describe this image in one short sentence."
ANSI_ESCAPE = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
ESTIMATED_PIXEL_BYTES = 4
ESTIMATED_ROW_ALIGNMENT = 16
TWO_GIB_BYTES = 1 << 31


@dataclass(frozen=True)
class AspectRatio:
    label: str
    width: int
    height: int

    def dimensions(self, long_edge: int) -> tuple[int, int]:
        if self.width >= self.height:
            width = long_edge
            height = max(1, round(long_edge * self.height / self.width))
        else:
            height = long_edge
            width = max(1, round(long_edge * self.width / self.height))
        return width, height


@dataclass(frozen=True)
class CommandResult:
    exit_code: int
    stdout: str
    stderr: str
    seconds: float
    timed_out: bool = False

    @property
    def combined_output(self) -> str:
        return "\n".join(part for part in (self.stdout, self.stderr) if part).strip()


def parse_ratio(value: str) -> AspectRatio:
    parts = value.strip().split(":")
    if len(parts) != 2:
        raise argparse.ArgumentTypeError(f"Invalid aspect ratio '{value}'; expected W:H.")

    try:
        width, height = (int(part) for part in parts)
    except ValueError as error:
        raise argparse.ArgumentTypeError(
            f"Invalid aspect ratio '{value}'; W and H must be integers."
        ) from error

    if width <= 0 or height <= 0:
        raise argparse.ArgumentTypeError(
            f"Invalid aspect ratio '{value}'; W and H must be positive."
        )

    divisor = math.gcd(width, height)
    normalized_width = width // divisor
    normalized_height = height // divisor
    return AspectRatio(
        label=f"{normalized_width}:{normalized_height}",
        width=normalized_width,
        height=normalized_height,
    )


def parse_ratios(value: str) -> list[AspectRatio]:
    ratios = [parse_ratio(item) for item in value.split(",") if item.strip()]
    if not ratios:
        raise argparse.ArgumentTypeError("Provide at least one aspect ratio.")
    return ratios


def parse_sizes(value: str) -> list[int]:
    try:
        sizes = [int(item) for item in value.split(",") if item.strip()]
    except ValueError as error:
        raise argparse.ArgumentTypeError("Sizes must be comma-separated integers.") from error

    if not sizes or any(size <= 0 for size in sizes):
        raise argparse.ArgumentTypeError("Sizes must contain positive integers.")
    return list(dict.fromkeys(sizes))


def parse_jpeg_quality(value: str) -> int:
    try:
        quality = int(value)
    except ValueError as error:
        raise argparse.ArgumentTypeError("JPEG quality must be an integer from 1 to 100.") from error
    if not 1 <= quality <= 100:
        raise argparse.ArgumentTypeError("JPEG quality must be an integer from 1 to 100.")
    return quality


def build_long_edges(
    start: int,
    maximum: int,
    growth: float,
    explicit_sizes: Sequence[int] | None = None,
) -> list[int]:
    if explicit_sizes:
        return list(explicit_sizes)
    if start <= 0 or maximum <= 0:
        raise ValueError("Start and maximum long edges must be positive.")
    if start > maximum:
        raise ValueError("Start long edge cannot exceed maximum long edge.")
    if growth <= 1:
        raise ValueError("Growth must be greater than 1.")

    sizes: list[int] = []
    current = start
    while current <= maximum:
        sizes.append(current)
        next_size = max(current + 1, round(current * growth))
        if next_size > maximum:
            break
        current = next_size

    if sizes[-1] != maximum:
        sizes.append(maximum)
    return sizes


def clean_output(value: str) -> str:
    return ANSI_ESCAPE.sub("", value).strip()


def preview(value: str, limit: int = 100) -> str:
    compact = " ".join(clean_output(value).split())
    if len(compact) <= limit:
        return compact
    return f"{compact[: limit - 3]}..."


def run_command(
    command: Sequence[str],
    timeout: float,
    environment: dict[str, str] | None = None,
) -> CommandResult:
    started_at = time.monotonic()
    try:
        completed = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=timeout,
            env=environment,
            check=False,
        )
        return CommandResult(
            exit_code=completed.returncode,
            stdout=clean_output(completed.stdout),
            stderr=clean_output(completed.stderr),
            seconds=time.monotonic() - started_at,
        )
    except subprocess.TimeoutExpired as error:
        stdout = error.stdout.decode() if isinstance(error.stdout, bytes) else error.stdout or ""
        stderr = error.stderr.decode() if isinstance(error.stderr, bytes) else error.stderr or ""
        return CommandResult(
            exit_code=124,
            stdout=clean_output(stdout),
            stderr=clean_output(stderr),
            seconds=time.monotonic() - started_at,
            timed_out=True,
        )


def image_properties(sips_path: str, image_path: Path, timeout: float) -> dict[str, object]:
    result = run_command(
        [sips_path, "-g", "pixelWidth", "-g", "pixelHeight", "-g", "format", str(image_path)],
        timeout=timeout,
    )
    if result.exit_code != 0:
        raise RuntimeError(result.combined_output or "Unable to inspect image.")

    width_match = re.search(r"pixelWidth:\s*(\d+)", result.stdout)
    height_match = re.search(r"pixelHeight:\s*(\d+)", result.stdout)
    format_match = re.search(r"format:\s*(\S+)", result.stdout)
    if not width_match or not height_match:
        raise RuntimeError(f"Unable to read image dimensions from sips output: {result.stdout}")

    return {
        "width": int(width_match.group(1)),
        "height": int(height_match.group(1)),
        "format": format_match.group(1) if format_match else "unknown",
        "bytes": image_path.stat().st_size,
    }


def generate_variant(
    sips_path: str,
    source: Path,
    destination: Path,
    width: int,
    height: int,
    image_format: str,
    jpeg_quality: int,
    timeout: float,
) -> CommandResult:
    destination.parent.mkdir(parents=True, exist_ok=True)
    command = [sips_path, "-s", "format", image_format]
    if image_format == "jpeg":
        command.extend(["-s", "formatOptions", str(jpeg_quality)])
    command.extend(["-z", str(height), str(width), str(source), "--out", str(destination)])
    return run_command(command, timeout=timeout)


def fm_environment() -> dict[str, str]:
    environment = os.environ.copy()
    environment["NO_COLOR"] = "1"
    environment["TERM"] = "dumb"
    return environment


def run_token_count(
    fm_path: str,
    image_path: Path,
    prompt: str,
    timeout: float,
) -> tuple[int | None, CommandResult]:
    result = run_command(
        [
            fm_path,
            "token-count",
            "--quiet",
            "--image",
            str(image_path),
            "--text",
            prompt,
        ],
        timeout=timeout,
        environment=fm_environment(),
    )
    try:
        token_count = int(result.stdout.strip()) if result.exit_code == 0 else None
    except ValueError:
        token_count = None
    return token_count, result


def run_response(
    fm_path: str,
    model: str,
    image_path: Path,
    prompt: str,
    timeout: float,
) -> CommandResult:
    return run_command(
        [
            fm_path,
            "respond",
            "--model",
            model,
            "--no-stream",
            "--greedy",
            "--image",
            str(image_path),
            "--text",
            prompt,
        ],
        timeout=timeout,
        environment=fm_environment(),
    )


def write_record(report_path: Path, record: dict[str, object]) -> None:
    with report_path.open("a", encoding="utf-8") as report:
        json.dump(record, report, sort_keys=True)
        report.write("\n")


def format_megapixels(width: int, height: int) -> float:
    return round(width * height / 1_000_000, 3)


def estimated_bgra_buffer(width: int, height: int) -> tuple[int, int]:
    unaligned_row_bytes = width * ESTIMATED_PIXEL_BYTES
    row_bytes = (
        (unaligned_row_bytes + ESTIMATED_ROW_ALIGNMENT - 1)
        // ESTIMATED_ROW_ALIGNMENT
        * ESTIMATED_ROW_ALIGNMENT
    )
    return row_bytes, row_bytes * height


def missing_expected_terms(response: str, expected_terms: Sequence[str]) -> list[str]:
    normalized_response = response.casefold()
    return [term for term in expected_terms if term.casefold() not in normalized_response]


def print_result(record: dict[str, object]) -> None:
    dimensions = f"{record['width']}x{record['height']}"
    file_mebibytes = int(record["bytes"]) / (1024 * 1024)
    status = "PASS" if record["success"] else "FAIL"
    detail = preview(str(record.get("response") or record.get("error") or ""))
    print(
        f"{str(record['ratio']):>7}  {dimensions:>13}  "
        f"{float(record['megapixels']):>8.2f} MP  {file_mebibytes:>7.2f} MiB  "
        f"{status:>4}  {float(record['response_seconds']):>6.2f}s  {detail}"
    )


def test_image(
    *,
    fm_path: str,
    model: str,
    image_path: Path,
    ratio: str,
    long_edge: int,
    prompt: str,
    timeout: float,
    include_token_count: bool,
    expected_terms: Sequence[str],
    properties: dict[str, object],
    generation_seconds: float,
) -> dict[str, object]:
    token_count: int | None = None
    token_result: CommandResult | None = None
    if include_token_count:
        token_count, token_result = run_token_count(fm_path, image_path, prompt, timeout)

    response_result = run_response(fm_path, model, image_path, prompt, timeout)
    response_text = response_result.stdout.strip()
    width = int(properties["width"])
    height = int(properties["height"])
    estimated_row_bytes, estimated_decoded_bytes = estimated_bgra_buffer(width, height)
    transport_success = response_result.exit_code == 0 and bool(response_text)
    missing_terms = (
        missing_expected_terms(response_text, expected_terms) if transport_success else []
    )
    semantic_success = transport_success and not missing_terms
    if not transport_success:
        error = response_result.combined_output or "The model returned no output."
    elif missing_terms:
        error = f"Missing expected response terms: {', '.join(missing_terms)}."
    else:
        error = ""

    return {
        "type": "test",
        "ratio": ratio,
        "long_edge": long_edge,
        "width": width,
        "height": height,
        "pixels": width * height,
        "megapixels": format_megapixels(width, height),
        "bytes": properties["bytes"],
        "format": properties["format"],
        "estimated_bgra_row_bytes": estimated_row_bytes,
        "estimated_bgra_bytes": estimated_decoded_bytes,
        "estimated_bgra_gibibytes": round(estimated_decoded_bytes / (1024**3), 6),
        "estimated_bgra_crosses_2_gib": estimated_decoded_bytes >= TWO_GIB_BYTES,
        "generation_seconds": round(generation_seconds, 4),
        "token_count": token_count,
        "token_count_exit_code": token_result.exit_code if token_result else None,
        "token_count_seconds": round(token_result.seconds, 4) if token_result else None,
        "token_count_error": (
            token_result.combined_output if token_result and token_result.exit_code != 0 else None
        ),
        "response_exit_code": response_result.exit_code,
        "response_seconds": round(response_result.seconds, 4),
        "response": response_text,
        "error": error,
        "expected_terms": list(expected_terms),
        "missing_expected_terms": missing_terms,
        "transport_success": transport_success,
        "semantic_success": semantic_success,
        "timed_out": response_result.timed_out,
        "success": semantic_success,
    }


def output_extension(image_format: str) -> str:
    return {"jpeg": "jpg", "png": "png", "heic": "heic"}[image_format]


def resolve_executable(value: str) -> str:
    if "/" in value:
        path = Path(value).expanduser().resolve()
        if path.is_file() and os.access(path, os.X_OK):
            return str(path)
        raise FileNotFoundError(f"Executable not found: {path}")

    resolved = shutil.which(value)
    if resolved:
        return resolved
    raise FileNotFoundError(f"Executable not found on PATH: {value}")


def macos_version_value(option: str) -> str:
    result = run_command(["/usr/bin/sw_vers", option], timeout=5)
    return result.stdout if result.exit_code == 0 else "unknown"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Generate progressively larger image variants and test them with Apple's fm CLI."
        )
    )
    parser.add_argument("image", type=Path, help="Source image to resample and test.")
    parser.add_argument(
        "--ratios",
        type=parse_ratios,
        default=parse_ratios(",".join(DEFAULT_RATIOS)),
        help=f"Comma-separated W:H ratios. Default: {','.join(DEFAULT_RATIOS)}",
    )
    parser.add_argument(
        "--sizes",
        type=parse_sizes,
        help="Explicit comma-separated long-edge sizes; overrides start/max/growth.",
    )
    parser.add_argument("--start-long-edge", type=int, default=512)
    parser.add_argument("--max-long-edge", type=int, default=8192)
    parser.add_argument("--growth", type=float, default=2.0)
    parser.add_argument(
        "--max-pixels",
        type=int,
        default=200_000_000,
        help="Safety cap per generated image; pass 0 to disable. Default: %(default)s",
    )
    parser.add_argument("--model", choices=("system", "pcc"), default="system")
    parser.add_argument("--prompt", default=DEFAULT_PROMPT)
    parser.add_argument(
        "--expect",
        action="append",
        default=[],
        help=(
            "Case-insensitive term that must appear in the response. Repeat for multiple terms."
        ),
    )
    parser.add_argument("--format", choices=("jpeg", "png", "heic"), default="jpeg")
    parser.add_argument("--jpeg-quality", type=parse_jpeg_quality, default=80)
    parser.add_argument("--timeout", type=float, default=60.0)
    parser.add_argument("--fm-path", default="/usr/bin/fm")
    parser.add_argument("--sips-path", default="/usr/bin/sips")
    parser.add_argument(
        "--output-dir",
        type=Path,
        help="Report directory. Defaults to a timestamped directory under /tmp.",
    )
    parser.add_argument(
        "--keep-images",
        action="store_true",
        help="Keep generated variants beside the JSONL report.",
    )
    parser.add_argument(
        "--include-token-count",
        action="store_true",
        help="Also run fm token-count. This is diagnostic and does not decide pass/fail.",
    )
    parser.add_argument(
        "--skip-source",
        action="store_true",
        help="Skip the original image and test only generated aspect-ratio variants.",
    )
    parser.add_argument(
        "--continue-after-failure",
        action="store_true",
        help="Continue larger sizes after a failed model response.",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    arguments = parser.parse_args(argv)

    source = arguments.image.expanduser().resolve()
    if not source.is_file():
        parser.error(f"Image does not exist: {source}")

    try:
        fm_path = resolve_executable(arguments.fm_path)
        sips_path = resolve_executable(arguments.sips_path)
        long_edges = build_long_edges(
            arguments.start_long_edge,
            arguments.max_long_edge,
            arguments.growth,
            arguments.sizes,
        )
    except (FileNotFoundError, ValueError) as error:
        parser.error(str(error))

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    output_directory = (
        arguments.output_dir.expanduser().resolve()
        if arguments.output_dir
        else Path(tempfile.gettempdir()) / "foundation-lab-image-probe" / timestamp
    )
    output_directory.mkdir(parents=True, exist_ok=True)
    report_path = output_directory / "results.jsonl"
    if report_path.exists():
        report_path.unlink()

    availability = run_command(
        [fm_path, "available", "--model", arguments.model],
        timeout=arguments.timeout,
        environment=fm_environment(),
    )
    metadata: dict[str, object] = {
        "type": "run",
        "started_at": datetime.now(timezone.utc).isoformat(),
        "source": str(source),
        "fm_path": fm_path,
        "model": arguments.model,
        "prompt": arguments.prompt,
        "expected_terms": arguments.expect,
        "ratios": [ratio.label for ratio in arguments.ratios],
        "long_edges": long_edges,
        "max_pixels": arguments.max_pixels,
        "output_format": arguments.format,
        "host": {
            "macos": macos_version_value("-productVersion") or platform.mac_ver()[0],
            "build": macos_version_value("-buildVersion"),
            "machine": platform.machine(),
        },
        "availability_exit_code": availability.exit_code,
        "availability": availability.combined_output,
    }
    write_record(report_path, metadata)

    print(f"Source: {source}")
    print(f"Model: {arguments.model} ({availability.combined_output or 'unknown availability'})")
    print(f"Report: {report_path}")
    print()
    print("  ratio     dimensions        pixels      file  test    time  response/error")

    successful_tests = 0
    failures: dict[str, dict[str, object]] = {}
    largest_successes: dict[str, dict[str, object]] = {}

    if not arguments.skip_source:
        try:
            properties = image_properties(sips_path, source, arguments.timeout)
            source_record = test_image(
                fm_path=fm_path,
                model=arguments.model,
                image_path=source,
                ratio="source",
                long_edge=max(int(properties["width"]), int(properties["height"])),
                prompt=arguments.prompt,
                timeout=arguments.timeout,
                include_token_count=arguments.include_token_count,
                expected_terms=arguments.expect,
                properties=properties,
                generation_seconds=0,
            )
            write_record(report_path, source_record)
            print_result(source_record)
            successful_tests += int(bool(source_record["success"]))
        except RuntimeError as error:
            source_error = {
                "type": "test",
                "ratio": "source",
                "success": False,
                "error": str(error),
            }
            write_record(report_path, source_error)
            print(f"{'source':>7}  {'unknown':>13}  {'-':>11}  {'-':>8}  FAIL         {error}")

    image_root = output_directory / "images"
    temporary_images: tempfile.TemporaryDirectory[str] | None = None
    if not arguments.keep_images:
        temporary_images = tempfile.TemporaryDirectory(prefix="foundation-lab-image-probe-")
        image_root = Path(temporary_images.name)

    extension = output_extension(arguments.format)
    try:
        for ratio in arguments.ratios:
            for long_edge in long_edges:
                width, height = ratio.dimensions(long_edge)
                pixels = width * height
                if arguments.max_pixels and pixels > arguments.max_pixels:
                    skipped = {
                        "type": "skipped",
                        "ratio": ratio.label,
                        "long_edge": long_edge,
                        "width": width,
                        "height": height,
                        "pixels": pixels,
                        "reason": (
                            f"Exceeded --max-pixels {arguments.max_pixels}; "
                            "raise the cap or pass 0 to disable it."
                        ),
                    }
                    write_record(report_path, skipped)
                    print(
                        f"{ratio.label:>7}  {f'{width}x{height}':>13}  "
                        f"{format_megapixels(width, height):>8.2f} MP  "
                        f"{'-':>7}      SKIP         {skipped['reason']}"
                    )
                    continue

                image_path = image_root / (
                    f"{ratio.width}x{ratio.height}-{width}x{height}.{extension}"
                )
                generated = generate_variant(
                    sips_path=sips_path,
                    source=source,
                    destination=image_path,
                    width=width,
                    height=height,
                    image_format=arguments.format,
                    jpeg_quality=arguments.jpeg_quality,
                    timeout=arguments.timeout,
                )
                if generated.exit_code != 0:
                    generation_failure = {
                        "type": "test",
                        "ratio": ratio.label,
                        "long_edge": long_edge,
                        "width": width,
                        "height": height,
                        "pixels": pixels,
                        "megapixels": format_megapixels(width, height),
                        "success": False,
                        "stage": "generation",
                        "error": generated.combined_output,
                        "generation_seconds": round(generated.seconds, 4),
                    }
                    write_record(report_path, generation_failure)
                    failures.setdefault(ratio.label, generation_failure)
                    print(
                        f"{ratio.label:>7}  {f'{width}x{height}':>13}  "
                        f"{format_megapixels(width, height):>8.2f} MP  "
                        f"{'-':>7}  FAIL  {generated.seconds:>6.2f}s  "
                        f"{preview(generated.combined_output)}"
                    )
                    break

                try:
                    properties = image_properties(sips_path, image_path, arguments.timeout)
                except RuntimeError as error:
                    inspection_failure = {
                        "type": "test",
                        "ratio": ratio.label,
                        "long_edge": long_edge,
                        "width": width,
                        "height": height,
                        "pixels": pixels,
                        "megapixels": format_megapixels(width, height),
                        "success": False,
                        "stage": "inspection",
                        "error": str(error),
                        "generation_seconds": round(generated.seconds, 4),
                    }
                    write_record(report_path, inspection_failure)
                    failures.setdefault(ratio.label, inspection_failure)
                    print(
                        f"{ratio.label:>7}  {f'{width}x{height}':>13}  "
                        f"{format_megapixels(width, height):>8.2f} MP  "
                        f"{'-':>7}  FAIL  {generated.seconds:>6.2f}s  {preview(str(error))}"
                    )
                    break

                record = test_image(
                    fm_path=fm_path,
                    model=arguments.model,
                    image_path=image_path,
                    ratio=ratio.label,
                    long_edge=long_edge,
                    prompt=arguments.prompt,
                    timeout=arguments.timeout,
                    include_token_count=arguments.include_token_count,
                    expected_terms=arguments.expect,
                    properties=properties,
                    generation_seconds=generated.seconds,
                )
                write_record(report_path, record)
                print_result(record)

                if record["success"]:
                    successful_tests += 1
                    largest_successes[ratio.label] = record
                else:
                    failures.setdefault(ratio.label, record)
                    if not arguments.continue_after_failure:
                        break
    finally:
        if temporary_images:
            temporary_images.cleanup()

    print()
    print("Summary")
    for ratio in arguments.ratios:
        success = largest_successes.get(ratio.label)
        failure = failures.get(ratio.label)
        if success and failure:
            print(
                f"- {ratio.label}: largest success {success['width']}x{success['height']} "
                f"({success['megapixels']:.2f} MP); first failure "
                f"{failure.get('width', '?')}x{failure.get('height', '?')}."
            )
        elif success:
            print(
                f"- {ratio.label}: no failure through {success['width']}x{success['height']} "
                f"({success['megapixels']:.2f} MP)."
            )
        elif failure:
            print(f"- {ratio.label}: failed at the first tested size.")
        else:
            print(f"- {ratio.label}: no generated size was tested.")

    print(f"- Full results: {report_path}")
    return 0 if successful_tests else 1


if __name__ == "__main__":
    sys.exit(main())
