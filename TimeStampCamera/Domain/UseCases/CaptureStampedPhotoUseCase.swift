import Foundation
import UIKit

@MainActor
struct CaptureStampedPhotoUseCase {
    private let locationProvider: LocationProviding
    private let mapRenderer: MapSnapshotRendering
    private let imageStamper: ImageStamping
    private let photoStore: PhotoRecordStoring
    private let photoLibrarySaver: PhotoLibrarySaving
    private let clock: () -> Date

    init(
        locationProvider: LocationProviding,
        mapRenderer: MapSnapshotRendering,
        imageStamper: ImageStamping,
        photoStore: PhotoRecordStoring,
        photoLibrarySaver: PhotoLibrarySaving,
        clock: @escaping () -> Date = Date.init
    ) {
        self.locationProvider = locationProvider
        self.mapRenderer = mapRenderer
        self.imageStamper = imageStamper
        self.photoStore = photoStore
        self.photoLibrarySaver = photoLibrarySaver
        self.clock = clock
    }

    func execute(
        sourceImage: UIImage,
        capturedAtOverride: Date? = nil,
        locationOverride: CapturedLocation? = nil
    ) async throws -> CaptureStampedPhotoResult {
        let preparedPhoto = try await prepareStampedPhoto(
            sourceImage: sourceImage,
            capturedAtOverride: capturedAtOverride,
            locationOverride: locationOverride
        )
        try await saveToPhotoLibrary(preparedPhoto.stampedImage)

        return CaptureStampedPhotoResult(record: preparedPhoto.record, stampedImage: preparedPhoto.stampedImage)
    }

    func prepareStampedPhoto(
        sourceImage: UIImage,
        capturedAtOverride: Date? = nil,
        locationOverride: CapturedLocation? = nil
    ) async throws -> PreparedStampedPhoto {
        let location: CapturedLocation
        if let locationOverride {
            location = locationOverride
        } else {
            location = try await locationProvider.currentLocation()
        }

        let mapImage = try await mapRenderer.renderSnapshot(
            centeredAt: location.coordinate,
            size: CGSize(width: 300, height: 185)
        )
        let metadata = StampMetadata(capturedAt: capturedAtOverride ?? clock(), location: location, mapImage: mapImage)
        let preparedImage = sourceImage.resizedForStamping(maxPixelDimension: 2_400)
        let stampedImage = imageStamper.stamp(image: preparedImage, metadata: metadata)
        let record = try photoStore.saveStampedPhoto(stampedImage, metadata: metadata)

        return PreparedStampedPhoto(record: record, stampedImage: stampedImage)
    }

    func saveToPhotoLibrary(_ stampedImage: UIImage) async throws {
        try await photoLibrarySaver.saveToPhotoLibrary(stampedImage)
    }
}

private extension UIImage {
    func resizedForStamping(maxPixelDimension: CGFloat) -> UIImage {
        let longestSide = max(size.width, size.height)
        guard longestSide > maxPixelDimension else {
            return self
        }

        let scale = maxPixelDimension / longestSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

struct CaptureStampedPhotoResult: Equatable {
    let record: PhotoRecord
    let stampedImage: UIImage

    static func == (lhs: CaptureStampedPhotoResult, rhs: CaptureStampedPhotoResult) -> Bool {
        lhs.record == rhs.record && lhs.stampedImage.pngData() == rhs.stampedImage.pngData()
    }
}

struct PreparedStampedPhoto: Equatable {
    let record: PhotoRecord
    let stampedImage: UIImage
}
