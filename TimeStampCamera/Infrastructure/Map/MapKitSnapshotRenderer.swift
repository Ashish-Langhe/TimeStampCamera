import CoreLocation
import MapKit
import UIKit

final class MapKitSnapshotRenderer: MapSnapshotRendering {
    private var cachedSnapshot: CachedMapSnapshot?

    func renderSnapshot(centeredAt coordinate: CLLocationCoordinate2D, size: CGSize) async throws -> UIImage {
        if let cachedSnapshot, cachedSnapshot.matches(coordinate: coordinate, size: size) {
            return cachedSnapshot.image
        }

        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 700,
            longitudinalMeters: 700
        )
        options.size = size
        options.scale = 1
        options.mapType = .standard

        let snapshot = try await MKMapSnapshotter(options: options).start()
        let image = drawPin(on: snapshot, coordinate: coordinate, size: size)
        cachedSnapshot = CachedMapSnapshot(coordinate: coordinate, size: size, image: image)
        return image
    }

    private func drawPin(on snapshot: MKMapSnapshotter.Snapshot, coordinate: CLLocationCoordinate2D, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            snapshot.image.draw(at: .zero)

            let point = snapshot.point(for: coordinate)
            let pinRect = CGRect(x: point.x - 9, y: point.y - 26, width: 18, height: 26)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: pinRect.midX, y: pinRect.maxY))
            path.addCurve(
                to: CGPoint(x: pinRect.minX, y: pinRect.minY + 9),
                controlPoint1: CGPoint(x: pinRect.midX - 10, y: pinRect.maxY - 7),
                controlPoint2: CGPoint(x: pinRect.minX, y: pinRect.midY)
            )
            path.addArc(
                withCenter: CGPoint(x: pinRect.midX, y: pinRect.minY + 9),
                radius: 9,
                startAngle: .pi,
                endAngle: 0,
                clockwise: true
            )
            path.addCurve(
                to: CGPoint(x: pinRect.midX, y: pinRect.maxY),
                controlPoint1: CGPoint(x: pinRect.maxX, y: pinRect.midY),
                controlPoint2: CGPoint(x: pinRect.midX + 10, y: pinRect.maxY - 7)
            )
            UIColor.systemRed.setFill()
            path.fill()

            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: CGRect(x: point.x - 3, y: point.y - 20, width: 6, height: 6))
        }
    }
}

private struct CachedMapSnapshot {
    let coordinate: CLLocationCoordinate2D
    let size: CGSize
    let image: UIImage

    func matches(coordinate: CLLocationCoordinate2D, size: CGSize) -> Bool {
        self.size == size && distance(from: self.coordinate, to: coordinate) < 30
    }

    private func distance(from lhs: CLLocationCoordinate2D, to rhs: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: lhs.latitude, longitude: lhs.longitude)
            .distance(from: CLLocation(latitude: rhs.latitude, longitude: rhs.longitude))
    }
}
