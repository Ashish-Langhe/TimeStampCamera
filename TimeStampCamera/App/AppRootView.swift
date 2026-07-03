import SwiftUI

struct AppRootView: View {
    @State private var isShowingSplash = true

    var body: some View {
        ZStack {
            if isShowingSplash {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        isShowingSplash = false
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 1.04)))
            } else {
                CameraView(
                    viewModel: CameraViewModel(
                        captureUseCase: AppDependencyFactory.makeCaptureUseCase(photoStore: AppDependencyFactory.makePhotoStore())
                    )
                )
                .tint(.orange)
                .transition(.opacity)
            }
        }
    }
}
