import SwiftUI
import UIKit

struct StampedPhotoPreview: View {
    let image: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.99, green: 1.00, blue: 0.98),
                            Color(red: 0.90, green: 0.96, blue: 0.93)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 0.12, green: 0.30, blue: 0.26).opacity(0.16), lineWidth: 1)
                }

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ZStack {
                    ViewfinderCorners()
                        .stroke(Color(red: 0.02, green: 0.42, blue: 0.36).opacity(0.30), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .padding(28)

                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.78))
                                .frame(width: 86, height: 86)
                            Image(systemName: "camera.aperture")
                                .font(.system(size: 42, weight: .semibold))
                                .foregroundStyle(Color(red: 0.91, green: 0.39, blue: 0.12))
                        }
                        Text("Ready to Capture")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(Color(red: 0.13, green: 0.18, blue: 0.17))
                        Text("Tap Open Camera")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(red: 0.46, green: 0.53, blue: 0.50))
                    }
                }
            }
        }
        .aspectRatio(3 / 4, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .shadow(color: Color(red: 0.10, green: 0.20, blue: 0.17).opacity(0.12), radius: 18, x: 0, y: 12)
    }
}

private struct ViewfinderCorners: Shape {
    func path(in rect: CGRect) -> Path {
        let length = min(rect.width, rect.height) * 0.16
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))

        path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))

        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - length, y: rect.maxY))

        path.move(to: CGPoint(x: rect.minX + length, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - length))

        return path
    }
}
