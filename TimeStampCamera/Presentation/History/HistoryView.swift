import Combine
import CoreLocation
import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel

    init(viewModel: HistoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.records.isEmpty {
                ContentUnavailableView(
                    "No stamped photos yet",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("Your locally saved stamped photos will appear here.")
                )
            } else {
                List(viewModel.records) { record in
                    HistoryRow(record: record, imageURL: viewModel.imageURL(for: record))
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("History")
        .task {
            viewModel.load()
        }
        .refreshable {
            viewModel.load()
        }
        .overlay(alignment: .bottom) {
            if let message = viewModel.errorMessage {
                InlineStatusView(
                    title: "History unavailable",
                    message: message,
                    systemImage: "exclamationmark.triangle.fill",
                    tint: .red
                )
                .padding()
            }
        }
    }
}

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published private(set) var records: [PhotoRecord] = []
    @Published private(set) var errorMessage: String?

    private let photoStore: PhotoRecordStoring

    init(photoStore: PhotoRecordStoring) {
        self.photoStore = photoStore
    }

    func load() {
        do {
            records = try photoStore.loadRecords().sorted { $0.createdAt > $1.createdAt }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func imageURL(for record: PhotoRecord) -> URL {
        photoStore.imageURL(for: record)
    }
}

private struct HistoryRow: View {
    let record: PhotoRecord
    let imageURL: URL

    var body: some View {
        HStack(spacing: 14) {
            LocalImageThumbnail(url: imageURL)

            VStack(alignment: .leading, spacing: 6) {
                Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.headline)
                Text(record.formattedAddress ?? record.locality ?? "Stamped location")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(String(format: "%.5f, %.5f", record.coordinate.latitude, record.coordinate.longitude))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)

            ShareLink(item: imageURL) {
                Image(systemName: "square.and.arrow.up")
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Share stamped photo")
        }
        .padding(.vertical, 6)
    }
}

private struct LocalImageThumbnail: View {
    let url: URL

    var body: some View {
        Group {
            if let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 72, height: 96)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
