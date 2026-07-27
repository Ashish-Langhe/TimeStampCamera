import CoreLocation
import Foundation
import UIKit

struct StampMetadata: Equatable {
    let capturedAt: Date
    let location: CapturedLocation
    let mapImage: UIImage
    let fontConfiguration: StampFontConfiguration
    let mapConfiguration: StampMapConfiguration

    init(
        capturedAt: Date,
        location: CapturedLocation,
        mapImage: UIImage,
        fontConfiguration: StampFontConfiguration = .default,
        mapConfiguration: StampMapConfiguration = .default
    ) {
        self.capturedAt = capturedAt
        self.location = location
        self.mapImage = mapImage
        self.fontConfiguration = fontConfiguration
        self.mapConfiguration = mapConfiguration
    }
}

struct StampFontConfiguration: Equatable {
    nonisolated static let `default` = StampFontConfiguration(timeSize: 54, locationSize: 54)

    let timeSize: CGFloat
    let locationSize: CGFloat

    init(timeSize: CGFloat, locationSize: CGFloat) {
        self.timeSize = min(max(timeSize, 30), 82)
        self.locationSize = min(max(locationSize, 30), 82)
    }
}

struct StampMapConfiguration: Equatable {
    nonisolated static let `default` = StampMapConfiguration(sizeScale: 1)

    let sizeScale: CGFloat

    init(sizeScale: CGFloat) {
        self.sizeScale = min(max(sizeScale, 0.65), 1.45)
    }
}
