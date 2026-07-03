import Combine
import Foundation
import UIKit

@MainActor
final class CameraViewModel: ObservableObject {
    enum PickerSource {
        case camera
        case photoLibrary

        var uiImagePickerSourceType: UIImagePickerController.SourceType {
            switch self {
            case .camera:
                UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
            case .photoLibrary:
                .photoLibrary
            }
        }
    }

    enum State: Equatable {
        case idle
        case stamping
        case completed(PhotoRecord)
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var stampedImage: UIImage?
    @Published var isImagePickerPresented = false
    @Published private(set) var pickerSource: PickerSource = .camera
    @Published private(set) var pendingTimestampOverride: Date?

    private let captureUseCase: CaptureStampedPhotoUseCase

    init(captureUseCase: CaptureStampedPhotoUseCase) {
        self.captureUseCase = captureUseCase
    }

    var isStamping: Bool {
        if case .stamping = state {
            return true
        }
        return false
    }

    func openCamera() {
        pickerSource = .camera
        isImagePickerPresented = true
    }

    func openPhotoLibraryForStamping() {
        pickerSource = .photoLibrary
        isImagePickerPresented = true
    }

    func setOneShotTimestampOverride(_ date: Date) {
        pendingTimestampOverride = date
    }

    func stampPickedImage(_ image: UIImage) {
        state = .stamping
        stampedImage = nil
        let timestampOverride = pendingTimestampOverride
        pendingTimestampOverride = nil

        Task {
            do {
                let result = try await captureUseCase.execute(sourceImage: image, capturedAtOverride: timestampOverride)
                stampedImage = result.stampedImage
                state = .completed(result.record)
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    func reset() {
        state = .idle
        stampedImage = nil
    }
}
