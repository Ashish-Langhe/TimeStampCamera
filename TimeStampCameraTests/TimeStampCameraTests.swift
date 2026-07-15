//
//  TimeStampCameraTests.swift
//  TimeStampCameraTests
//
//  Created by Ashish Langhe on 30/06/26.
//

import CoreLocation
import Testing
import UIKit
@testable import TimeStampCamera

struct TimeStampCameraTests {

    @MainActor
    @Test func captureUseCaseComposesLocationMapStampAndStorage() async throws {
        let fixedDate = Date(timeIntervalSince1970: 1_782_768_600)
        let location = CapturedLocation(
            coordinate: CLLocationCoordinate2D(latitude: 19.076, longitude: 72.8777),
            horizontalAccuracy: 8,
            locality: "Mumbai",
            formattedAddress: "Mumbai, Maharashtra, India"
        )
        let mapImage = TestImageFactory.image(color: .systemBlue)
        let stampedImage = TestImageFactory.image(color: .systemGreen)
        let store = SpyPhotoRecordStore()

        let useCase = CaptureStampedPhotoUseCase(
            locationProvider: StubLocationProvider(location: location),
            mapRenderer: SpyMapSnapshotRenderer(mapImage: mapImage),
            imageStamper: SpyImageStamper(stampedImage: stampedImage),
            photoStore: store,
            photoLibrarySaver: SpyPhotoLibrarySaver(),
            clock: { fixedDate }
        )

        let result = try await useCase.execute(sourceImage: TestImageFactory.image(color: .systemOrange))

        #expect(result.record.createdAt == fixedDate)
        #expect(result.record.coordinate.latitude == 19.076)
        #expect(result.record.formattedAddress == "Mumbai, Maharashtra, India")
        #expect(store.savedMetadata?.capturedAt == fixedDate)
        #expect(store.savedMetadata?.location == location)
    }

    @Test func stampDateFormatterUsesStableStampShape() {
        let formatter = DefaultStampDateFormatter(
            timeZone: TimeZone(secondsFromGMT: 0)!,
            locale: Locale(identifier: "en_US_POSIX")
        )
        let date = Date(timeIntervalSince1970: 1_782_768_600.123)

        #expect(formatter.string(from: date) == "30 Jun 2026, 5:30 AM")
        #expect(formatter.dateString(from: date) == "30 Jun 2026")
        #expect(formatter.referenceStyleString(from: date) == "Jun 30, 2026 at 5:30:00 AM")
        #expect(formatter.timeString(from: date) == "5:30:00 AM GMT")
        #expect(formatter.timestampString(from: date) == "2026-06-30T05:30:00Z")
    }

    @MainActor
    @Test func captureUseCaseUsesProvidedOneShotTimestampOverride() async throws {
        let defaultClockDate = Date(timeIntervalSince1970: 1_782_768_600)
        let overrideDate = Date(timeIntervalSince1970: 1_700_000_000)
        let location = CapturedLocation(
            coordinate: CLLocationCoordinate2D(latitude: 19.076, longitude: 72.8777),
            horizontalAccuracy: 8,
            locality: "Mumbai",
            formattedAddress: "Mumbai, Maharashtra, India"
        )
        let store = SpyPhotoRecordStore()
        let useCase = CaptureStampedPhotoUseCase(
            locationProvider: StubLocationProvider(location: location),
            mapRenderer: SpyMapSnapshotRenderer(mapImage: TestImageFactory.image(color: .systemBlue)),
            imageStamper: SpyImageStamper(stampedImage: TestImageFactory.image(color: .systemGreen)),
            photoStore: store,
            photoLibrarySaver: SpyPhotoLibrarySaver(),
            clock: { defaultClockDate }
        )

        _ = try await useCase.execute(
            sourceImage: TestImageFactory.image(color: .systemOrange),
            capturedAtOverride: overrideDate
        )

        #expect(store.savedMetadata?.capturedAt == overrideDate)
    }

    @MainActor
    @Test func captureUseCaseUsesProvidedOneShotLocationOverride() async throws {
        let detectedLocation = CapturedLocation(
            coordinate: CLLocationCoordinate2D(latitude: 19.076, longitude: 72.8777),
            horizontalAccuracy: 8,
            locality: "Mumbai",
            formattedAddress: "Mumbai, Maharashtra, India"
        )
        let overrideLocation = CapturedLocation(
            coordinate: CLLocationCoordinate2D(latitude: 18.6298, longitude: 73.7997),
            horizontalAccuracy: 0,
            locality: "Pimpri Chinchwad",
            formattedAddress: "Pimpri Chinchwad, Maharashtra, India"
        )
        let store = SpyPhotoRecordStore()
        let mapRenderer = SpyMapSnapshotRenderer(mapImage: TestImageFactory.image(color: .systemBlue))
        let useCase = CaptureStampedPhotoUseCase(
            locationProvider: StubLocationProvider(location: detectedLocation),
            mapRenderer: mapRenderer,
            imageStamper: SpyImageStamper(stampedImage: TestImageFactory.image(color: .systemGreen)),
            photoStore: store,
            photoLibrarySaver: SpyPhotoLibrarySaver()
        )

        _ = try await useCase.prepareStampedPhoto(
            sourceImage: TestImageFactory.image(color: .systemOrange),
            locationOverride: overrideLocation
        )

        #expect(store.savedMetadata?.location == overrideLocation)
        #expect(mapRenderer.renderedCoordinate?.latitude == overrideLocation.coordinate.latitude)
        #expect(mapRenderer.renderedCoordinate?.longitude == overrideLocation.coordinate.longitude)
    }

    @MainActor
    @Test func prepareStampedPhotoDoesNotWaitForPhotoLibrarySave() async throws {
        let location = CapturedLocation(
            coordinate: CLLocationCoordinate2D(latitude: 19.076, longitude: 72.8777),
            horizontalAccuracy: 8,
            locality: "Mumbai",
            formattedAddress: "Mumbai, Maharashtra, India"
        )
        let photoLibrarySaver = SpyPhotoLibrarySaver()
        let useCase = CaptureStampedPhotoUseCase(
            locationProvider: StubLocationProvider(location: location),
            mapRenderer: SpyMapSnapshotRenderer(mapImage: TestImageFactory.image(color: .systemBlue)),
            imageStamper: SpyImageStamper(stampedImage: TestImageFactory.image(color: .systemGreen)),
            photoStore: SpyPhotoRecordStore(),
            photoLibrarySaver: photoLibrarySaver
        )

        _ = try await useCase.prepareStampedPhoto(sourceImage: TestImageFactory.image(color: .systemOrange))

        #expect(photoLibrarySaver.saveCount == 0)
    }

}

@MainActor
private final class SpyPhotoLibrarySaver: PhotoLibrarySaving {
    private(set) var saveCount = 0

    func saveToPhotoLibrary(_ image: UIImage) async throws {
        saveCount += 1
    }
}

private enum TestImageFactory {
    static func image(color: UIColor) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24)).image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 24, height: 24))
        }
    }
}

private struct StubLocationProvider: LocationProviding {
    let location: CapturedLocation

    func currentLocation() async throws -> CapturedLocation {
        location
    }
}

@MainActor
private final class SpyMapSnapshotRenderer: MapSnapshotRendering {
    let mapImage: UIImage
    private(set) var renderedCoordinate: CLLocationCoordinate2D?

    init(mapImage: UIImage) {
        self.mapImage = mapImage
    }

    func renderSnapshot(centeredAt coordinate: CLLocationCoordinate2D, size: CGSize) async throws -> UIImage {
        renderedCoordinate = coordinate
        return mapImage
    }
}

private struct SpyImageStamper: ImageStamping {
    let stampedImage: UIImage

    func stamp(image: UIImage, metadata: StampMetadata) -> UIImage {
        stampedImage
    }
}

@MainActor
private final class SpyPhotoRecordStore: PhotoRecordStoring {
    private(set) var savedMetadata: StampMetadata?

    func saveStampedPhoto(_ image: UIImage, metadata: StampMetadata) throws -> PhotoRecord {
        savedMetadata = metadata
        return PhotoRecord(
            id: UUID(uuidString: "7BF1DA8B-EFC0-4B01-9655-46F04708CB56")!,
            createdAt: metadata.capturedAt,
            imageFileName: "test.jpg",
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
