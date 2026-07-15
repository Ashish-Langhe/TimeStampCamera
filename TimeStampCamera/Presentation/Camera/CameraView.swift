import SwiftUI
import UIKit

struct CameraView: View {
    @StateObject private var viewModel: CameraViewModel
    @State private var didAutoOpenCamera = false
    @State private var hiddenTapCount = 0
    @State private var isSecretSettingsPresented = false
    @State private var shouldOpenPhotoLibraryAfterSecretDismiss = false

    init(viewModel: CameraViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    CameraPalette.canvasTop,
                    CameraPalette.canvasMiddle,
                    CameraPalette.canvasBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                CameraHeaderView()
                    .padding(.top, 4)

                StampedPhotoPreview(image: viewModel.stampedImage)
                    .contentShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture {
                        handlePreviewTap()
                    }
                    .overlay(alignment: .center) {
                        if viewModel.isStamping {
                            ProgressView("Stamping photo")
                                .padding(18)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        }
                    }

                statusContent

                HStack(spacing: 10) {
                    Button {
                        viewModel.openCamera()
                    } label: {
                        Label(viewModel.stampedImage == nil ? "Open Camera" : "Capture Again", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CameraPrimaryButtonStyle())
                    .controlSize(.large)
                    .disabled(viewModel.isStamping)

                    Button {
                        viewModel.reset()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(CameraIconButtonStyle())
                    .disabled(viewModel.stampedImage == nil || viewModel.isStamping)
                    .accessibilityLabel("Reset")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .task {
            guard !didAutoOpenCamera else {
                return
            }
            didAutoOpenCamera = true
            viewModel.openCamera()
        }
        .fullScreenCover(isPresented: $viewModel.isImagePickerPresented) {
            CameraImagePicker(sourceType: viewModel.pickerSource.uiImagePickerSourceType) { image in
                viewModel.stampPickedImage(image)
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isSecretSettingsPresented) {
            SecretTimestampSettingsView(
                onUseOnce: { selectedDate in
                    viewModel.setOneShotTimestampOverride(selectedDate)
                },
                onStampExistingPhoto: { selectedDate in
                    viewModel.setOneShotTimestampOverride(selectedDate)
                    shouldOpenPhotoLibraryAfterSecretDismiss = true
                }
            )
            .presentationDetents([.medium, .large])
        }
        .onChange(of: isSecretSettingsPresented) { _, isPresented in
            guard !isPresented, shouldOpenPhotoLibraryAfterSecretDismiss else {
                return
            }
            shouldOpenPhotoLibraryAfterSecretDismiss = false
            viewModel.openPhotoLibraryForStamping()
        }
    }

    private func handlePreviewTap() {
        guard !viewModel.isStamping else {
            return
        }

        hiddenTapCount += 1
        if hiddenTapCount >= 5 {
            hiddenTapCount = 0
            isSecretSettingsPresented = true
        }
    }

    @ViewBuilder
    private var statusContent: some View {
        switch viewModel.state {
        case .idle:
            InlineStatusView(
                title: UIImagePickerController.isSourceTypeAvailable(.camera) ? "Camera ready" : "Camera unavailable",
                message: idleStatusMessage,
                systemImage: "camera.fill",
                tint: .orange
            )
        case .stamping:
            InlineStatusView(
                title: "Stamping immediately",
                message: "Getting your current location, creating the map pin, and saving the stamped image.",
                systemImage: "map.fill",
                tint: .orange
            )
        case .savingToPhotos:
            InlineStatusView(
                title: "Stamp ready",
                message: "Final save to Photos is finishing in the background.",
                systemImage: "photo.badge.checkmark.fill",
                tint: .orange
            )
        case .completed(let record):
            InlineStatusView(
                title: "Saved to Photos",
                message: "Stamped \(record.createdAt.formatted(date: .abbreviated, time: .shortened))",
                systemImage: "checkmark.seal.fill",
                tint: .green
            )
        case .failed(let message):
            InlineStatusView(
                title: "Could not stamp photo",
                message: message,
                systemImage: "exclamationmark.triangle.fill",
                tint: .red
            )
        }
    }

    private var idleStatusMessage: String {
        if let pendingTimestampOverride = viewModel.pendingTimestampOverride {
            return "One custom timestamp is ready: \(pendingTimestampOverride.formatted(date: .abbreviated, time: .shortened)). Location will still be current."
        }

        return UIImagePickerController.isSourceTypeAvailable(.camera)
            ? "Date, time, location, coordinates, and map will be added to the saved photo."
            : "This environment has no camera, so photo library fallback is used."
    }
}

private enum CameraPalette {
    static let canvasTop = Color(red: 0.96, green: 0.98, blue: 0.96)
    static let canvasMiddle = Color(red: 0.90, green: 0.96, blue: 0.94)
    static let canvasBottom = Color(red: 0.98, green: 0.94, blue: 0.87)
    static let ink = Color(red: 0.13, green: 0.18, blue: 0.17)
    static let muted = Color(red: 0.46, green: 0.53, blue: 0.50)
    static let teal = Color(red: 0.02, green: 0.42, blue: 0.36)
    static let orange = Color(red: 0.91, green: 0.39, blue: 0.12)
    static let border = Color(red: 0.12, green: 0.30, blue: 0.26).opacity(0.12)
}

private struct CameraHeaderView: View {
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(CameraPalette.teal)
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 46, height: 46)
            .shadow(color: CameraPalette.teal.opacity(0.20), radius: 12, x: 0, y: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text("Timestamp Camera")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(CameraPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text("Camera-ready progress stamps")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CameraPalette.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 0)

            Label("Live", systemImage: "location.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(CameraPalette.teal)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.white.opacity(0.72), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(CameraPalette.border, lineWidth: 1)
                }
        }
        .padding(12)
        .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(CameraPalette.border, lineWidth: 1)
        }
    }
}

private struct CameraPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    colors: [
                        CameraPalette.orange,
                        Color(red: 0.72, green: 0.25, blue: 0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .shadow(color: Color(red: 0.58, green: 0.22, blue: 0.08).opacity(configuration.isPressed ? 0.10 : 0.22), radius: configuration.isPressed ? 4 : 12, x: 0, y: configuration.isPressed ? 2 : 8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private struct CameraIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(CameraPalette.teal)
            .background(.white.opacity(configuration.isPressed ? 0.68 : 0.88), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(CameraPalette.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

private struct SecretTimestampSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    let onUseOnce: (Date) -> Void
    let onStampExistingPhoto: (Date) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Stamp date and time",
                        selection: $selectedDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                } footer: {
                    Text("This timestamp applies once. Location is still detected normally.")
                }

                Section {
                    Button {
                        onStampExistingPhoto(selectedDate)
                        dismiss()
                    } label: {
                        Label("Stamp Existing Photo", systemImage: "photo.on.rectangle")
                    }
                } footer: {
                    Text("Choose a photo from your library, stamp it, and save the stamped copy back to Photos.")
                }
            }
            .navigationTitle("Secret Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Use Once") {
                        onUseOnce(selectedDate)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
