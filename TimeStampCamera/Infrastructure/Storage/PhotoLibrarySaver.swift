import Photos
import UIKit

@MainActor
struct PhotoLibrarySaver: PhotoLibrarySaving {
    func saveToPhotoLibrary(_ image: UIImage) async throws {
        let status = await requestAuthorizationIfNeeded()
        guard status == .authorized || status == .limited else {
            throw PhotoLibrarySaveError.permissionDenied
        }

        guard let data = image.jpegData(compressionQuality: 0.88) else {
            throw PhotoLibrarySaveError.imageEncodingFailed
        }

        try await PHPhotoLibrary.shared().performChanges {
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: data, options: nil)
        }
    }

    private func requestAuthorizationIfNeeded() async -> PHAuthorizationStatus {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        guard currentStatus == .notDetermined else {
            return currentStatus
        }

        return await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    }
}

enum PhotoLibrarySaveError: LocalizedError {
    case permissionDenied
    case imageEncodingFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "Photo library permission is required to save the stamped image to Photos."
        case .imageEncodingFailed:
            "The stamped image could not be prepared for saving."
        }
    }
}
