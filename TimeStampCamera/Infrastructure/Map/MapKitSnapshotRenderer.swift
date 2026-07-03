import CoreLocation
import MapKit
import UIKit

struct MapKitSnapshotRenderer: MapSnapshotRendering {
    func renderSnapshot(centeredAt coordinate: CLLocationCoordinate2D, size: CGSize) async throws -> UIImage {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 700,
            longitudinalMeters: 700
        )
        options.size = size
        options.scale = UIScreen.main.scale
        options.mapType = .standard

        let snapshot = try await MKMapSnapshotter(options: options).start()
        return drawPin(on: snapshot, coordinate: coordinate, size: size)
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
