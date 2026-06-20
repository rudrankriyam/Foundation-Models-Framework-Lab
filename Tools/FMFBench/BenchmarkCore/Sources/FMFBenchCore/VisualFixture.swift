#if compiler(>=6.4)
    import CoreGraphics
    import Foundation
    import FoundationModels

    // Drawing commands intentionally remain sequential so the synthetic fixture is reproducible.
    // swiftlint:disable function_body_length
    @available(macOS 27.0, iOS 27.0, visionOS 27.0, *)
    public func fmfBenchPrompt(for sample: FMFBenchSample) throws -> Prompt {
        guard sample.visualFixture != nil else {
            return Prompt(sample.prompt)
        }

        let image = try sunsetRunFixture()
        return Prompt {
            sample.prompt
            Attachment(image).label("A synthetic running video frame")
        }
    }

    @available(macOS 27.0, iOS 27.0, visionOS 27.0, *)
    private func sunsetRunFixture() throws -> CGImage {
        let width = 640
        let height = 420
        guard
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
            let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            throw CocoaError(.coderInvalidValue)
        }

        let colors =
            [
                CGColor(red: 0.13, green: 0.20, blue: 0.45, alpha: 1),
                CGColor(red: 0.95, green: 0.37, blue: 0.25, alpha: 1),
                CGColor(red: 1.00, green: 0.73, blue: 0.32, alpha: 1)
            ] as CFArray
        let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: colors,
            locations: [0, 0.58, 1]
        )
        if let gradient {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: height),
                end: CGPoint(x: 0, y: 0),
                options: []
            )
        }

        context.setFillColor(CGColor(red: 1, green: 0.86, blue: 0.42, alpha: 1))
        context.fillEllipse(in: CGRect(x: 465, y: 225, width: 86, height: 86))

        context.setFillColor(CGColor(red: 0.08, green: 0.30, blue: 0.43, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: 150))

        context.setFillColor(CGColor(red: 0.09, green: 0.14, blue: 0.20, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: 78))

        context.setStrokeColor(CGColor(gray: 0.05, alpha: 1))
        context.setFillColor(CGColor(gray: 0.05, alpha: 1))
        context.setLineWidth(15)
        context.fillEllipse(in: CGRect(x: 285, y: 215, width: 34, height: 34))
        context.move(to: CGPoint(x: 302, y: 215))
        context.addLine(to: CGPoint(x: 326, y: 160))
        context.addLine(to: CGPoint(x: 370, y: 138))
        context.move(to: CGPoint(x: 323, y: 175))
        context.addLine(to: CGPoint(x: 274, y: 160))
        context.move(to: CGPoint(x: 326, y: 160))
        context.addLine(to: CGPoint(x: 302, y: 108))
        context.addLine(to: CGPoint(x: 258, y: 83))
        context.move(to: CGPoint(x: 326, y: 160))
        context.addLine(to: CGPoint(x: 359, y: 108))
        context.addLine(to: CGPoint(x: 405, y: 102))
        context.strokePath()

        guard let image = context.makeImage() else {
            throw CocoaError(.coderInvalidValue)
        }
        return image
    }
    // swiftlint:enable function_body_length
#endif
