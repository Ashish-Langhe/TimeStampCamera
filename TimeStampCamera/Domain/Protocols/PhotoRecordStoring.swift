import UIKit

@MainActor
protocol PhotoRecordStoring {
    func saveStampedPhoto(_ image: UIImage, metadata: StampMetadata) throws -> PhotoRecord
    func loadRecords() throws -> [PhotoRecord]
    func imageURL(for record: PhotoRecord) -> URL
}
