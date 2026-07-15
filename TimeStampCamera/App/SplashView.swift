import SwiftUI
import UIKit

struct SplashView: View {
    let onFinished: () -> Void

    @State private var iconScale = 0.72
    @State private var iconRotation = -8.0
    @State private var iconOpacity = 0.0
    @State private var titleOffset: CGFloat = 18
    @State private var titleOpacity = 0.0
    @State private var ringProgress = 0.0
    @State private var pulseScale = 0.86
    @State private var shimmerOffset: CGFloat = -260

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.27, blue: 0.31),
                    Color(red: 0.02, green: 0.46, blue: 0.38),
                    Color(red: 0.96, green: 0.57, blue: 0.13)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            MapGridBackground()
                .opacity(0.28)

            Circle()
                .fill(.white.opacity(0.10))
                .frame(width: 252, height: 252)
                .scaleEffect(pulseScale)
                .blur(radius: 1)

            VStack(spacing: 26) {
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.20), lineWidth: 4)
                        .frame(width: 176, height: 176)

                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            AngularGradient(
                                colors: [.white, .orange, .cyan, .white],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .frame(width: 176, height: 176)
                        .rotationEffect(.degrees(-90))

                    AppIconImage()
                        .frame(width: 132, height: 132)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .shadow(color: .black.opacity(0.28), radius: 22, x: 0, y: 16)
                        .overlay {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(.white.opacity(0.34), lineWidth: 1)
                        }
                        .scaleEffect(iconScale)
                        .rotationEffect(.degrees(iconRotation))
                        .opacity(iconOpacity)
                }

                VStack(spacing: 9) {
                    Text("Timestamp Camera")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .overlay(alignment: .leading) {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.85), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 72)
                                .offset(x: shimmerOffset)
                                .blendMode(.overlay)
                        }
                        .clipShape(Rectangle())

                    Text("Stamp every healthy moment")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)
            }
            .padding(.bottom, 22)
        }
        .task {
            await animateAndFinish()
        }
    }

    private func animateAndFinish() async {
        withAnimation(.spring(response: 0.65, dampingFraction: 0.72)) {
            iconScale = 1
            iconRotation = 0
            iconOpacity = 1
            pulseScale = 1.18
        }
        withAnimation(.easeOut(duration: 0.72).delay(0.12)) {
            ringProgress = 1
            titleOffset = 0
            titleOpacity = 1
        }
        withAnimation(.easeInOut(duration: 0.95).delay(0.35)) {
            shimmerOffset = 260
        }

        try? await Task.sleep(nanoseconds: 1_750_000_000)
        onFinished()
    }
}

private struct AppIconImage: View {
    var body: some View {
        if let image = Bundle.main.image(named: "Icon-60@3x", subdirectory: "AppIcons") ??
            Bundle.main.image(named: "AppIcon-ios-marketing-1024x1024-1x", subdirectory: "Assets.xcassets/AppIcon.appiconset") {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "camera.viewfinder")
                .resizable()
                .scaledToFit()
                .padding(28)
                .foregroundStyle(.white)
                .background(Color.orange)
        }
    }
}

private struct MapGridBackground: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let spacing: CGFloat = 46
                let offset = CGFloat(phase.truncatingRemainder(dividingBy: 3)) * 8
                var path = Path()

                stride(from: -size.height, through: size.width + size.height, by: spacing).forEach { x in
                    path.move(to: CGPoint(x: x + offset, y: 0))
                    path.addLine(to: CGPoint(x: x + size.height + offset, y: size.height))
                }

                stride(from: 0, through: size.height + size.width, by: spacing * 1.6).forEach { y in
                    path.move(to: CGPoint(x: 0, y: y - offset))
                    path.addLine(to: CGPoint(x: size.width, y: y - size.width * 0.38 - offset))
                }

                context.stroke(path, with: .color(.white.opacity(0.62)), lineWidth: 1.2)
            }
        }
        .ignoresSafeArea()
    }
}

private extension Bundle {
    func image(named name: String, subdirectory: String) -> UIImage? {
        guard let url = url(forResource: name, withExtension: "png", subdirectory: subdirectory) else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }
}
