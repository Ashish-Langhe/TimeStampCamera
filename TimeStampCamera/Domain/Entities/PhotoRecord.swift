import CoreLocation
import Foundation

struct PhotoRecord: Identifiable, Equatable {
    let id: UUID
    let createdAt: Date
    let imageFileName: String
    let coordinate: CLLocationCoordinate2D
    let locality: String?
    let formattedAddress: String?

    static func == (lhs: PhotoRecord, rhs: PhotoRecord) -> Bool {
        lhs.id == rhs.id &&
        lhs.createdAt == rhs.createdAt &&
        lhs.imageFileName == rhs.imageFileName &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.locality == rhs.locality &&
        lhs.formattedAddress == rhs.formattedAddress
    }
}
