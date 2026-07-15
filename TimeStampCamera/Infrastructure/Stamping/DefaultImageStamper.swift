import CoreLocation
import UIKit

struct DefaultImageStamper: ImageStamping {
    private let dateFormatter: StampDateFormatting

    init(dateFormatter: StampDateFormatting = DefaultStampDateFormatter()) {
        self.dateFormatter = dateFormatter
    }

    func stamp(image: UIImage, metadata: StampMetadata) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
            drawTopRightStamp(metadata: metadata, imageSize: image.size)
            drawMap(metadata.mapImage, imageSize: image.size, stampLineCount: stampLines(for: metadata).count)
        }
    }

    private func drawTopRightStamp(metadata: StampMetadata, imageSize: CGSize) {
        let layout = stampLayout(for: imageSize)
        let fontSize = layout.fontSize

        let lines = stampLines(for: metadata)
        let rect = layout.rect(lineCount: lines.count)
        drawTextBacking(behind: rect, in: imageSize)
        drawHeaderTitle(
            in: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: layout.headerHeight),
            fontSize: fontSize
        )

        for (index, line) in lines.enumerated() {
            let lineRect = CGRect(
                x: rect.minX,
                y: rect.minY + layout.headerHeight + layout.headerSpacing + CGFloat(index) * layout.lineHeight,
                width: rect.width,
                height: layout.lineHeight * 1.08
            )
            drawShadowed(line, in: lineRect, font: .systemFont(ofSize: fontSize, weight: .semibold), alignment: .right)
        }
    }

    private func drawHeaderTitle(in rect: CGRect, fontSize: CGFloat) {
        let title = "Timestamp Camera"
        let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        let iconSize = fontSize * 0.92
        let spacing = fontSize * 0.22
        let titleWidth = (title as NSString).size(withAttributes: [.font: font]).width
        let contentWidth = iconSize + spacing + titleWidth
        let startX = rect.midX - contentWidth / 2
        let iconRect = CGRect(
            x: startX,
            y: rect.midY - iconSize / 2,
            width: iconSize,
            height: iconSize
        )
        let titleRect = CGRect(
            x: iconRect.maxX + spacing,
            y: rect.minY,
            width: titleWidth + 4,
            height: rect.height
        )

        drawStampHeaderIcon(in: iconRect)
        drawShadowed(title, in: titleRect, font: font, alignment: .left)
    }

    private func drawStampHeaderIcon(in rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.setShadow(offset: CGSize(width: 0, height: 3), blur: 7, color: UIColor.black.withAlphaComponent(0.86).cgColor)

        let bodyRect = rect.insetBy(dx: rect.width * 0.04, dy: rect.height * 0.16)
        let bodyPath = UIBezierPath(roundedRect: bodyRect, cornerRadius: rect.height * 0.18)
        UIColor(red: 0.02, green: 0.48, blue: 0.42, alpha: 1).setFill()
        bodyPath.fill()

        let topRect = CGRect(
            x: bodyRect.minX + bodyRect.width * 0.18,
            y: rect.minY + rect.height * 0.08,
            width: bodyRect.width * 0.34,
            height: rect.height * 0.18
        )
        let topPath = UIBezierPath(roundedRect: topRect, cornerRadius: rect.height * 0.07)
        UIColor(red: 0.01, green: 0.34, blue: 0.31, alpha: 1).setFill()
        topPath.fill()

        let lensOuterRect = CGRect(
            x: bodyRect.midX - rect.width * 0.20,
            y: bodyRect.midY - rect.height * 0.20,
            width: rect.width * 0.40,
            height: rect.height * 0.40
        )
        UIColor.white.withAlphaComponent(0.96).setFill()
        UIBezierPath(ovalIn: lensOuterRect).fill()

        let lensInnerRect = lensOuterRect.insetBy(dx: rect.width * 0.075, dy: rect.height * 0.075)
        UIColor(red: 0.94, green: 0.42, blue: 0.12, alpha: 1).setFill()
        UIBezierPath(ovalIn: lensInnerRect).fill()

        UIColor.white.withAlphaComponent(0.95).setFill()
        UIBezierPath(ovalIn: CGRect(
            x: lensInnerRect.minX + lensInnerRect.width * 0.18,
            y: lensInnerRect.minY + lensInnerRect.height * 0.16,
            width: lensInnerRect.width * 0.23,
            height: lensInnerRect.height * 0.23
        )).fill()

        let pinCenter = CGPoint(x: bodyRect.maxX - rect.width * 0.12, y: bodyRect.minY + rect.height * 0.18)
        let pinRadius = rect.width * 0.12
        let pinPath = UIBezierPath()
        pinPath.move(to: CGPoint(x: pinCenter.x, y: pinCenter.y + pinRadius * 1.65))
        pinPath.addCurve(
            to: CGPoint(x: pinCenter.x - pinRadius, y: pinCenter.y),
            controlPoint1: CGPoint(x: pinCenter.x - pinRadius * 0.72, y: pinCenter.y + pinRadius),
            controlPoint2: CGPoint(x: pinCenter.x - pinRadius, y: pinCenter.y + pinRadius * 0.48)
        )
        pinPath.addArc(
            withCenter: pinCenter,
            radius: pinRadius,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        pinPath.addCurve(
            to: CGPoint(x: pinCenter.x, y: pinCenter.y + pinRadius * 1.65),
            controlPoint1: CGPoint(x: pinCenter.x + pinRadius, y: pinCenter.y + pinRadius * 0.48),
            controlPoint2: CGPoint(x: pinCenter.x + pinRadius * 0.72, y: pinCenter.y + pinRadius)
        )
        UIColor(red: 0.94, green: 0.42, blue: 0.12, alpha: 1).setFill()
        pinPath.fill()

        UIColor.white.setFill()
        UIBezierPath(ovalIn: CGRect(
            x: pinCenter.x - pinRadius * 0.32,
            y: pinCenter.y - pinRadius * 0.32,
            width: pinRadius * 0.64,
            height: pinRadius * 0.64
        )).fill()

        context?.restoreGState()
    }

    private func drawTextBacking(behind rect: CGRect, in imageSize: CGSize) {
        let padding = max(imageSize.width * 0.016, 12)
        let backingRect = rect.insetBy(dx: -padding, dy: -padding * 0.8)
        let path = UIBezierPath(roundedRect: backingRect, cornerRadius: 18)
        UIColor.black.withAlphaComponent(0.18).setFill()
        path.fill()
    }

    private func stampLines(for metadata: StampMetadata) -> [String] {
        let addressParts = (metadata.location.formattedAddress ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let locationLines = addressParts.isEmpty
            ? [metadata.location.locality ?? "Current Location"]
            : Array(addressParts.suffix(4))

        let latitude = String(format: "%.6f", metadata.location.coordinate.latitude)
        let longitude = String(format: "%.6f", metadata.location.coordinate.longitude)

        return [
            dateFormatter.referenceStyleString(from: metadata.capturedAt)
        ] + locationLines + [
            "Lat \(latitude)",
            "Long \(longitude)"
        ]
    }

    private func drawMap(_ mapImage: UIImage, imageSize: CGSize, stampLineCount: Int) {
        let margin = imageSize.width * 0.045
        let mapWidth = min(imageSize.width * 0.52, 560)
        let mapHeight = mapWidth * 0.66
        let stampRect = stampLayout(for: imageSize).rect(lineCount: stampLineCount)
        let availableBottom = imageSize.height - margin
        let preferredY = stampRect.maxY + margin * 0.7
        let yPosition = min(preferredY, max(stampRect.maxY + margin * 0.25, availableBottom - mapHeight))
        let rect = CGRect(
            x: imageSize.width - mapWidth - margin,
            y: yPosition,
            width: mapWidth,
            height: mapHeight
        )

        let shadowPath = UIBezierPath(roundedRect: rect.insetBy(dx: -5, dy: -5), cornerRadius: 20)
        UIColor.black.withAlphaComponent(0.30).setFill()
        shadowPath.fill(with: .normal, alpha: 1)

        let clipPath = UIBezierPath(roundedRect: rect, cornerRadius: 18)
        clipPath.addClip()
        mapImage.draw(in: rect)

        UIColor.white.withAlphaComponent(0.96).setStroke()
        clipPath.lineWidth = max(imageSize.width * 0.004, 3)
        clipPath.stroke()
    }

    private func drawShadowed(_ text: String, in rect: CGRect, font: UIFont, alignment: NSTextAlignment, color: UIColor = .white) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = .byTruncatingTail

        let shadow = NSShadow()
        shadow.shadowColor = UIColor.black.withAlphaComponent(0.86)
        shadow.shadowBlurRadius = 7
        shadow.shadowOffset = CGSize(width: 0, height: 3)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
            .shadow: shadow,
            .strokeColor: UIColor.black.withAlphaComponent(0.62),
            .strokeWidth: -1.8
        ]
        (text as NSString).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
    }

    private func stampLayout(for imageSize: CGSize) -> StampLayout {
        let margin = imageSize.width * 0.045
        let width = imageSize.width * 0.72
        let fontSize = min(max(imageSize.width * 0.046, 30), 54)
        let lineHeight = fontSize * 1.18
        let headerHeight = lineHeight
        let headerSpacing = lineHeight * 0.16
        return StampLayout(
            origin: CGPoint(x: imageSize.width - width - margin, y: margin * 0.7),
            width: width,
            fontSize: fontSize,
            lineHeight: lineHeight,
            headerHeight: headerHeight,
            headerSpacing: headerSpacing
        )
    }
}

private struct StampLayout {
    let origin: CGPoint
    let width: CGFloat
    let fontSize: CGFloat
    let lineHeight: CGFloat
    let headerHeight: CGFloat
    let headerSpacing: CGFloat

    func rect(lineCount: Int) -> CGRect {
        return CGRect(
            x: origin.x,
            y: origin.y,
            width: width,
            height: headerHeight + headerSpacing + CGFloat(lineCount) * lineHeight + lineHeight * 0.34
        )
    }
}
