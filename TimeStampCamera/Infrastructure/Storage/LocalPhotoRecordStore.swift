import CoreLocation
import Foundation
import UIKit

@MainActor
final class LocalPhotoRecordStore: PhotoRecordStoring {
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func saveStampedPhoto(_ image: UIImage, metadata: StampMetadata) throws -> PhotoRecord {
        let id = UUID()
        let fileName = "\(id.uuidString).jpg"
        let imageURL = try stampedPhotosDirectory().appendingPathComponent(fileName)

        guard let imageData = image.jpegData(compressionQuality: 0.92) else {
            throw PhotoRecordStoreError.imageEncodingFailed
        }

        try imageData.write(to: imageURL, options: [.atomic])

        let record = PhotoRecord(
            id: id,
            createdAt: metadata.capturedAt,
            imageFileName: fileName,
            coordinate: metadata.location.coordinate,
            locality: metadata.location.locality,
            formattedAddress: metadata.location.formattedAddress
        )

        var records = try loadRecords()
        records.insert(record, at: 0)
        try persist(records: records)
        return record
    }

    func loadRecords() throws -> [PhotoRecord] {
        let url = recordsURL()
        guard fileManager.fileExists(atPath: url.path) else {
            return []
        }

        let data = try Data(contentsOf: url)
        return try decoder.decode([StoredPhotoRecord].self, from: data).map(\.record)
    }

    func imageURL(for record: PhotoRecord) -> URL {
        (try? stampedPhotosDirectory().appendingPathComponent(record.imageFileName)) ??
        documentsDirectory().appendingPathComponent("StampedPhotos").appendingPathComponent(record.imageFileName)
    }

    private func persist(records: [PhotoRecord]) throws {
        let data = try encoder.encode(records.map(StoredPhotoRecord.init(record:)))
        try data.write(to: recordsURL(), options: [.atomic])
    }

    private func stampedPhotosDirectory() throws -> URL {
        let directory = documentsDirectory().appendingPathComponent("StampedPhotos", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    private func recordsURL() -> URL {
        documentsDirectory().appendingPathComponent("photo-records.json")
    }

    private func documentsDirectory() -> URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

enum PhotoRecordStoreError: Error {
    case imageEncodingFailed
}

private struct StoredPhotoRecord: Codable {
    let id: UUID
    let createdAt: Date
    let imageFileName: String
    let latitude: Double
    let longitude: Double
    let locality: String?
    let formattedAddress: String?

    init(record: PhotoRecord) {
        self.id = record.id
        self.createdAt = record.createdAt
        self.imageFileName = record.imageFileName
        self.latitude = record.coordinate.latitude
        self.longitude = record.coordinate.longitude
        self.locality = record.locality
        self.formattedAddress = record.formattedAddress
    }

    var record: PhotoRecord {
        PhotoRecord(
            id: id,
            createdAt: createdAt,
            imageFileName: imageFileName,
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            locality: locality,
            formattedAddress: formattedAddress
        )
    }
}
