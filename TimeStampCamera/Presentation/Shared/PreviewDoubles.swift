import CoreLocation
import UIKit

struct PreviewLocationProvider: LocationProviding {
    func currentLocation() async throws -> CapturedLocation {
        CapturedLocation(
            coordinate: CLLocationCoordinate2D(latitude: 19.0760, longitude: 72.8777),
            horizontalAccuracy: 12,
            locality: "Mumbai",
            formattedAddress: "Mumbai, Maharashtra, India"
        )
    }
}

struct PreviewMapSnapshotRenderer: MapSnapshotRendering {
    func renderSnapshot(centeredAt coordinate: CLLocationCoordinate2D, size: CGSize) async throws -> UIImage {
        UIGraphicsImageRenderer(size: size).image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIColor.white.withAlphaComponent(0.35).setStroke()
            for offset in stride(from: 0, through: size.width, by: 36) {
                context.cgContext.move(to: CGPoint(x: offset, y: 0))
                context.cgContext.addLine(to: CGPoint(x: offset, y: size.height))
            }
            for offset in stride(from: 0, through: size.height, by: 36) {
                context.cgContext.move(to: CGPoint(x: 0, y: offset))
                context.cgContext.addLine(to: CGPoint(x: size.width, y: offset))
            }
            context.cgContext.strokePath()
        }
    }
}

@MainActor
final class PreviewPhotoRecordStore: PhotoRecordStoring {
    func saveStampedPhoto(_ image: UIImage, metadata: StampMetadata) throws -> PhotoRecord {
        PhotoRecord(
            id: UUID(),
            createdAt: metadata.capturedAt,
            imageFileName: "preview.jpg",
            coordinate: metadata.location.coordinate,
            locality: metadata.location.locality,
            formattedAddress: metadata.location.formattedAddress
        )
    }

    func loadRecords() throws -> [PhotoRecord] {
        []
    }

    func imageURL(for record: PhotoRecord) -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(record.imageFileName)
    }
}

struct PreviewPhotoLibrarySaver: PhotoLibrarySaving {
    func saveToPhotoLibrary(_ image: UIImage) async throws {}
}
