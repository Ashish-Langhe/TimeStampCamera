import CoreLocation
import Foundation
import UIKit

struct StampMetadata: Equatable {
    let capturedAt: Date
    let location: CapturedLocation
    let mapImage: UIImage
}
