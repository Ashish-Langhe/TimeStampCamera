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
        case savingToPhotos(PhotoRecord)
        case completed(PhotoRecord)
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var stampedImage: UIImage?
    @Published var isImagePickerPresented = false
    @Published private(set) var pickerSource: PickerSource = .camera
    @Published private(set) var pendingTimestampOverride: Date?
    @Published private(set) var pendingLocationOverride: CapturedLocation?
    @Published private(set) var pendingFontConfiguration: StampFontConfiguration?
    @Published private(set) var pendingMapConfiguration: StampMapConfiguration?

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

    func setOneShotOverrides(
        timestamp: Date,
        location: CapturedLocation?,
        fontConfiguration: StampFontConfiguration = .default,
        mapConfiguration: StampMapConfiguration = .default
    ) {
        pendingTimestampOverride = timestamp
        pendingLocationOverride = location
        pendingFontConfiguration = fontConfiguration
        pendingMapConfiguration = mapConfiguration
    }

    func stampPickedImage(_ image: UIImage) {
        state = .stamping
        stampedImage = nil
        let timestampOverride = pendingTimestampOverride
        let locationOverride = pendingLocationOverride
        let fontConfiguration = pendingFontConfiguration ?? .default
        let mapConfiguration = pendingMapConfiguration ?? .default
        pendingTimestampOverride = nil
        pendingLocationOverride = nil
        pendingFontConfiguration = nil
        pendingMapConfiguration = nil

        Task {
            do {
                let preparedPhoto = try await captureUseCase.prepareStampedPhoto(
                    sourceImage: image,
                    capturedAtOverride: timestampOverride,
                    locationOverride: locationOverride,
                    fontConfiguration: fontConfiguration,
                    mapConfiguration: mapConfiguration
                )
                stampedImage = preparedPhoto.stampedImage
                state = .savingToPhotos(preparedPhoto.record)

                try await captureUseCase.saveToPhotoLibrary(preparedPhoto.stampedImage)
                state = .completed(preparedPhoto.record)
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
