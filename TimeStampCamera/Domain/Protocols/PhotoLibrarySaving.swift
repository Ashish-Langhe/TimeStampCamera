import UIKit

@MainActor
protocol PhotoLibrarySaving {
    func saveToPhotoLibrary(_ image: UIImage) async throws
}
