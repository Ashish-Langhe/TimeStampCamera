@MainActor
enum AppDependencyFactory {
    static func makeCaptureUseCase(photoStore: PhotoRecordStoring) -> CaptureStampedPhotoUseCase {
        CaptureStampedPhotoUseCase(
            locationProvider: CoreLocationProvider(),
            mapRenderer: MapKitSnapshotRenderer(),
            imageStamper: DefaultImageStamper(),
            photoStore: photoStore,
            photoLibrarySaver: PhotoLibrarySaver()
        )
    }

    static func makePhotoStore() -> LocalPhotoRecordStore {
        LocalPhotoRecordStore()
    }
}
