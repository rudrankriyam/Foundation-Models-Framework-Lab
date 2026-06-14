# Foundation Models Image Input Probe

This CLI empirically tests image inputs against Apple's shipped `fm` command. It
accepts any source image, resamples it into progressively larger common aspect
ratios, sends each variant through the model, and records the first failure.

## What Apple documents

As of June 14, 2026, Apple's public Foundation Models documentation does not
publish a maximum pixel width, height, megapixel count, file size, or aspect
ratio for image attachments.

Apple does document that:

- `Attachment` accepts image file URLs, `CGImage`, `CIImage`, and
  `CVPixelBuffer`.
- The framework performs scaling and color conversion before model inference,
  so callers do not need to pre-scale images just to satisfy the API.
- Apple's Origami sample includes unscaled JPEGs as large as `5712x4284`
  (about 24.5 MP).

There is also a recent Apple Developer Forums Q&A asking for ideal image size
and preprocessing guidance, but it does not currently have an answer.

These sources describe behavior, not a contractual maximum. Any measured
boundary may vary by OS build, model update, device memory, file format, and
whether the system or Private Cloud Compute model is selected.

## Initial macOS 27 beta observation

On June 14, 2026, the system model on macOS 27.0 build `26A5353q` was tested
with a Display P3 JPEG from Apple's Origami sample. The image contains a yellow
diamond on a blue background. The prompt required the response to identify both
`diamond` and `blue`.

| Ratio | Largest correct result | First incorrect result |
| --- | ---: | ---: |
| 1:1 | `23168x23168` | `23169x23169` |
| 16:9 | `30892x17377` | `30893x17377` |
| 9:16 | `17376x30891` | `17377x30892` |
| 4:3 | `26753x20065` | `26754x20066` |

The calls above the boundary still exited successfully, but the model
consistently reported a black background and a circle. This is a semantic
failure, not an API rejection.

The four boundaries align with an estimated 4-byte BGRA decode buffer, using a
16-byte-aligned row stride, crossing `2^31` bytes:

```text
alignedRowBytes = ceil((width * 4) / 16) * 16
estimatedDecodedBytes = alignedRowBytes * height
```

The JSONL report includes this estimate for every test. This relationship is an
inference from current behavior, not a documented Apple limit, and should be
retested on later OS/model builds and with other image formats.

## Run

Requirements:

- macOS 27 with Apple Intelligence enabled
- `/usr/bin/fm` and `/usr/bin/sips`
- Python 3

Start with the source image, then sweep square and common landscape/portrait
ratios from a 512-pixel long edge through 8192 pixels:

```bash
Tools/ImageInputProbe/image_input_probe.py path/to/photo.jpg
```

Test only square and 16:9 images through a larger cap:

```bash
Tools/ImageInputProbe/image_input_probe.py path/to/photo.jpg \
  --ratios 1:1,16:9 \
  --max-long-edge 16384 \
  --max-pixels 300000000
```

Use exact long-edge sizes:

```bash
Tools/ImageInputProbe/image_input_probe.py path/to/photo.jpg \
  --ratios 1:1,16:9,9:16 \
  --sizes 512,1024,2048,4096,8192,12288
```

Verify that the model still understands known image content, not just that the
request returns:

```bash
Tools/ImageInputProbe/image_input_probe.py path/to/known-photo.jpg \
  --prompt "What shape is centered, and what color is the background?" \
  --expect diamond \
  --expect blue
```

Keep generated images and write the report inside the repo:

```bash
Tools/ImageInputProbe/image_input_probe.py path/to/photo.jpg \
  --output-dir tmp/image-input-probe/run-1 \
  --keep-images
```

The default report is a timestamped `results.jsonl` under
`/tmp/foundation-lab-image-probe/`.

## Pass criteria

A test passes only when `fm respond` exits successfully, returns a nonempty
model response, and includes every optional `--expect` term. The report
preserves separate transport and semantic status, dimensions, megapixels,
encoded file size, generation time, inference time, response text, exit status,
and raw error.

`fm token-count --image` can be enabled with `--include-token-count`, but it is
diagnostic only. On the macOS 27 beta tested on June 14, 2026, token counting
returned `com.apple.VisionCore error 6` for images that worked correctly with
`fm respond`.

## Sources

- [Analyzing images with multimodal prompting](https://developer.apple.com/documentation/FoundationModels/analyzing-images-with-multimodal-prompting)
- [Attachment](https://developer.apple.com/documentation/foundationmodels/attachment)
- [ImageAttachmentContent](https://developer.apple.com/documentation/foundationmodels/imageattachmentcontent)
- [Origami sample](https://developer.apple.com/documentation/foundationmodels/origami-crafting-a-dynamic-tutorial-for-apple-intelligence)
- [Foundation Models Q&A](https://developer.apple.com/forums/activities/1570080)
