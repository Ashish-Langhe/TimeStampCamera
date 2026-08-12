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
        case savingToPhotos
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
    private let stampPresentationSettingsStore: StampPresentationSettingsStoring

    init(
        captureUseCase: CaptureStampedPhotoUseCase,
        stampPresentationSettingsStore: StampPresentationSettingsStoring? = nil
    ) {
        self.captureUseCase = captureUseCase
        self.stampPresentationSettingsStore = stampPresentationSettingsStore ?? UserDefaultsStampPresentationSettingsStore()
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
        let fontConfiguration = pendingFontConfiguration ?? stampPresentationSettingsStore.fontConfiguration
        let mapConfiguration = pendingMapConfiguration ?? stampPresentationSettingsStore.mapConfiguration
        pendingTimestampOverride = nil
        pendingLocationOverride = nil
        pendingFontConfiguration = nil
        pendingMapConfiguration = nil

        Task {
            do {
                let renderedPhoto = try await captureUseCase.renderStampedPhoto(
                    sourceImage: image,
                    capturedAtOverride: timestampOverride,
                    locationOverride: locationOverride,
                    fontConfiguration: fontConfiguration,
                    mapConfiguration: mapConfiguration
                )
                stampedImage = renderedPhoto.stampedImage
                state = .savingToPhotos

                async let savedRecord = captureUseCase.saveStampedPhotoRecord(renderedPhoto.stampedImage, metadata: renderedPhoto.metadata)
                async let photoLibrarySave: Void = captureUseCase.saveToPhotoLibrary(renderedPhoto.stampedImage)
                let record = try await savedRecord
                try await photoLibrarySave
                state = .completed(record)
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

protocol StampPresentationSettingsStoring {
    var fontConfiguration: StampFontConfiguration { get set }
    var mapConfiguration: StampMapConfiguration { get set }
}

enum StampPresentationSettingsKeys {
    static let timeFontSize = "stampPresentation.timeFontSize"
    static let locationFontSize = "stampPresentation.locationFontSize"
    static let mapSizeScale = "stampPresentation.mapSizeScale"
}

struct UserDefaultsStampPresentationSettingsStore: StampPresentationSettingsStoring {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var fontConfiguration: StampFontConfiguration {
        get {
            StampFontConfiguration(
                timeSize: storedCGFloat(
                    forKey: StampPresentationSettingsKeys.timeFontSize,
                    fallback: StampFontConfiguration.default.timeSize
                ),
                locationSize: storedCGFloat(
                    forKey: StampPresentationSettingsKeys.locationFontSize,
                    fallback: StampFontConfiguration.default.locationSize
                )
            )
        }
        set {
            userDefaults.set(Double(newValue.timeSize), forKey: StampPresentationSettingsKeys.timeFontSize)
            userDefaults.set(Double(newValue.locationSize), forKey: StampPresentationSettingsKeys.locationFontSize)
        }
    }

    var mapConfiguration: StampMapConfiguration {
        get {
            StampMapConfiguration(
                sizeScale: storedCGFloat(
                    forKey: StampPresentationSettingsKeys.mapSizeScale,
                    fallback: StampMapConfiguration.default.sizeScale
                )
            )
        }
        set {
            userDefaults.set(Double(newValue.sizeScale), forKey: StampPresentationSettingsKeys.mapSizeScale)
        }
    }

    private func storedCGFloat(forKey key: String, fallback: CGFloat) -> CGFloat {
        guard userDefaults.object(forKey: key) != nil else {
            return fallback
        }
        return CGFloat(userDefaults.double(forKey: key))
    }
}
