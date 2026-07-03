import CoreLocation
import Foundation

struct CapturedLocation: Equatable {
    let coordinate: CLLocationCoordinate2D
    let horizontalAccuracy: CLLocationAccuracy
    let locality: String?
    let formattedAddress: String?

    static func == (lhs: CapturedLocation, rhs: CapturedLocation) -> Bool {
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.horizontalAccuracy == rhs.horizontalAccuracy &&
        lhs.locality == rhs.locality &&
        lhs.formattedAddress == rhs.formattedAddress
    }
}
