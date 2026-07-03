import CoreLocation
import UIKit

@MainActor
protocol MapSnapshotRendering {
    func renderSnapshot(centeredAt coordinate: CLLocationCoordinate2D, size: CGSize) async throws -> UIImage
}
