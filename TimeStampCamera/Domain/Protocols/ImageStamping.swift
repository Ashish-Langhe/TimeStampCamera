import UIKit

@MainActor
protocol ImageStamping {
    func stamp(image: UIImage, metadata: StampMetadata) -> UIImage
}
