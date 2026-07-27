import Combine
import CoreLocation
import MapKit
import SwiftUI
import UIKit

struct CameraView: View {
    @StateObject private var viewModel: CameraViewModel
    @State private var didAutoOpenCamera = false
    @State private var isStampSettingsPresented = false
    @State private var shouldOpenPhotoLibraryAfterSettingsDismiss = false

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
                CameraHeaderView {
                    isStampSettingsPresented = true
                }
                    .padding(.top, 4)

                StampedPhotoPreview(image: viewModel.stampedImage)
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
        .sheet(isPresented: $isStampSettingsPresented) {
            StampSettingsView(
                onUseOnce: { selectedDate, selectedLocation, fontConfiguration, mapConfiguration in
                    viewModel.setOneShotOverrides(
                        timestamp: selectedDate,
                        location: selectedLocation,
                        fontConfiguration: fontConfiguration,
                        mapConfiguration: mapConfiguration
                    )
                },
                onStampExistingPhoto: { selectedDate, selectedLocation, fontConfiguration, mapConfiguration in
                    viewModel.setOneShotOverrides(
                        timestamp: selectedDate,
                        location: selectedLocation,
                        fontConfiguration: fontConfiguration,
                        mapConfiguration: mapConfiguration
                    )
                    shouldOpenPhotoLibraryAfterSettingsDismiss = true
                }
            )
            .presentationDetents([.medium, .large])
        }
        .onChange(of: isStampSettingsPresented) { _, isPresented in
            guard !isPresented, shouldOpenPhotoLibraryAfterSettingsDismiss else {
                return
            }
            shouldOpenPhotoLibraryAfterSettingsDismiss = false
            viewModel.openPhotoLibraryForStamping()
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
            if let pendingLocationOverride = viewModel.pendingLocationOverride {
                let locationName = pendingLocationOverride.locality ?? "custom location"
                return "One custom timestamp is ready: \(pendingTimestampOverride.formatted(date: .abbreviated, time: .shortened)) with \(locationName)."
            }

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
    let onSettingsTapped: () -> Void

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

            HStack(spacing: 8) {
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

                Button {
                    onSettingsTapped()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 17, weight: .bold))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(CameraHeaderIconButtonStyle())
                .accessibilityLabel("Stamp settings")
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

private struct CameraHeaderIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(CameraPalette.teal)
            .background(.white.opacity(configuration.isPressed ? 0.58 : 0.78), in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(CameraPalette.border, lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
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

private struct StampSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var selectedSecond = Calendar.current.component(.second, from: Date())
    @State private var useCustomLocation = false
    @State private var selectedCustomLocation: CapturedLocation?
    @State private var isLocationPickerPresented = false
    @State private var timeFontSize = Double(StampFontConfiguration.default.timeSize)
    @State private var locationFontSize = Double(StampFontConfiguration.default.locationSize)
    @State private var mapSizeScale = Double(StampMapConfiguration.default.sizeScale)
    let onUseOnce: (Date, CapturedLocation?, StampFontConfiguration, StampMapConfiguration) -> Void
    let onStampExistingPhoto: (Date, CapturedLocation?, StampFontConfiguration, StampMapConfiguration) -> Void

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
                    Text("Use this when you need the next stamped photo to use a specific date and time.")
                }

                Section {
                    Stepper(value: $selectedSecond, in: 0...59) {
                        HStack {
                            Text("Second")
                            Spacer()
                            Text("\(selectedSecond)")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Precision")
                } footer: {
                    Text("Seconds are included in the custom timestamp.")
                }

                Section {
                    Toggle("Use custom location", isOn: $useCustomLocation)

                    if useCustomLocation {
                        Button {
                            isLocationPickerPresented = true
                        } label: {
                            Label(
                                selectedCustomLocation == nil ? "Browse and Select on Map" : "Change Selected Location",
                                systemImage: "map"
                            )
                        }

                        if let selectedCustomLocation {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(selectedCustomLocation.locality ?? "Selected Location")
                                    .font(.subheadline.weight(.semibold))
                                if let formattedAddress = selectedCustomLocation.formattedAddress {
                                    Text(formattedAddress)
                                        .foregroundStyle(.secondary)
                                }
                                Text(
                                    "Lat \(selectedCustomLocation.coordinate.latitude.formatted(.number.precision(.fractionLength(5)))), Long \(selectedCustomLocation.coordinate.longitude.formatted(.number.precision(.fractionLength(5))))"
                                )
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        } else {
                            Text("Select a place or tap the map so the stamp can use the exact pin and coordinates.")
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("Location")
                } footer: {
                    Text("When enabled, this coordinate is used for the stamp text and map pin. Otherwise, the app uses your current location.")
                }

                Section {
                    StampFontSizeSlider(
                        title: "Time font size",
                        value: $timeFontSize
                    )

                    StampFontSizeSlider(
                        title: "Location font size",
                        value: $locationFontSize
                    )
                } header: {
                    Text("Stamp Text Size")
                } footer: {
                    Text("These sizes apply to the next stamped image only.")
                }

                Section {
                    StampMapSizeSlider(value: $mapSizeScale)
                } header: {
                    Text("Map Size")
                } footer: {
                    Text("This changes the mini map size on the next stamped image only.")
                }

                Section {
                    Button {
                        onStampExistingPhoto(customTimestamp, customLocation, fontConfiguration, mapConfiguration)
                        dismiss()
                    } label: {
                        Label("Stamp Existing Photo", systemImage: "photo.on.rectangle")
                    }
                    .disabled(useCustomLocation && customLocation == nil)
                } footer: {
                    Text("Choose a photo from your library, stamp it, and save the stamped copy back to Photos.")
                }
            }
            .navigationTitle("Stamp Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply Once") {
                        onUseOnce(customTimestamp, customLocation, fontConfiguration, mapConfiguration)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(useCustomLocation && customLocation == nil)
                }
            }
            .sheet(isPresented: $isLocationPickerPresented) {
                LocationSelectionView(initialLocation: selectedCustomLocation) { location in
                    selectedCustomLocation = location
                    useCustomLocation = true
                }
            }
        }
    }

    private var customTimestamp: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: selectedDate)
        components.second = selectedSecond
        components.nanosecond = 0
        return Calendar.current.date(from: components) ?? selectedDate
    }

    private var fontConfiguration: StampFontConfiguration {
        StampFontConfiguration(
            timeSize: CGFloat(timeFontSize),
            locationSize: CGFloat(locationFontSize)
        )
    }

    private var mapConfiguration: StampMapConfiguration {
        StampMapConfiguration(sizeScale: CGFloat(mapSizeScale))
    }

    private var customLocation: CapturedLocation? {
        useCustomLocation ? selectedCustomLocation : nil
    }
}

private struct LocationSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: LocationSelectionViewModel
    let onSelect: (CapturedLocation) -> Void

    init(initialLocation: CapturedLocation?, onSelect: @escaping (CapturedLocation) -> Void) {
        _viewModel = StateObject(wrappedValue: LocationSelectionViewModel(initialLocation: initialLocation))
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchHeader

                MapCoordinatePicker(
                    selectedCoordinate: $viewModel.selectedCoordinate,
                    selectedTitle: viewModel.selectedLocation?.locality ?? "Selected Location"
                )
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .task(id: viewModel.selectedCoordinate.latitude) {
                    await viewModel.reverseGeocodeSelectedCoordinate()
                }
                .task(id: viewModel.selectedCoordinate.longitude) {
                    await viewModel.reverseGeocodeSelectedCoordinate()
                }

                List {
                    if let selectedLocation = viewModel.selectedLocation {
                        Section("Selected Pin") {
                            LocationSummaryRow(location: selectedLocation)
                        }
                    }

                    if viewModel.isSearching {
                        Section {
                            HStack {
                                ProgressView()
                                Text("Searching places")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else if !viewModel.results.isEmpty {
                        Section("Search Results") {
                            ForEach(viewModel.results) { result in
                                Button {
                                    viewModel.selectSearchResult(result)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(result.title)
                                            .foregroundStyle(.primary)
                                        if let subtitle = result.subtitle {
                                            Text(subtitle)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 3)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.query, prompt: "Search area, gym, restaurant")
            .onSubmit(of: .search) {
                Task {
                    await viewModel.search()
                }
            }
            .onChange(of: viewModel.query) { _, query in
                viewModel.scheduleSearch(for: query)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Use Pin") {
                        guard let selectedLocation = viewModel.selectedLocation else {
                            return
                        }
                        onSelect(selectedLocation)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.selectedLocation == nil)
                }
            }
        }
        .presentationDetents([.large])
    }

    private var searchHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Search for a place or tap the map to set the exact stamp pin.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}

private struct LocationSummaryRow: View {
    let location: CapturedLocation

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(location.locality ?? "Selected Location")
                .font(.subheadline.weight(.semibold))
            if let formattedAddress = location.formattedAddress {
                Text(formattedAddress)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(
                "Lat \(location.coordinate.latitude.formatted(.number.precision(.fractionLength(5)))), Long \(location.coordinate.longitude.formatted(.number.precision(.fractionLength(5))))"
            )
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct LocationSearchResult: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    let location: CapturedLocation
}

@MainActor
private final class LocationSelectionViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [LocationSearchResult] = []
    @Published var selectedCoordinate: CLLocationCoordinate2D
    @Published var selectedLocation: CapturedLocation?
    @Published var isSearching = false
    @Published var errorMessage: String?

    private let geocoder = CLGeocoder()
    private var searchTask: Task<Void, Never>?
    private var reverseGeocodeTask: Task<Void, Never>?

    init(initialLocation: CapturedLocation?) {
        let defaultCoordinate = CLLocationCoordinate2D(latitude: 19.0760, longitude: 72.8777)
        selectedCoordinate = initialLocation?.coordinate ?? defaultCoordinate
        selectedLocation = initialLocation
    }

    func scheduleSearch(for query: String) {
        searchTask?.cancel()
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= 3 else {
            results = []
            isSearching = false
            return
        }

        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled else {
                return
            }
            await self?.search()
        }
    }

    func search() async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= 2 else {
            results = []
            return
        }

        isSearching = true
        errorMessage = nil
        defer {
            isSearching = false
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmedQuery
        request.region = MKCoordinateRegion(
            center: selectedCoordinate,
            latitudinalMeters: 80_000,
            longitudinalMeters: 80_000
        )

        do {
            let response = try await MKLocalSearch(request: request).start()
            results = response.mapItems.map { item in
                let location = Self.location(from: item)
                return LocationSearchResult(
                    title: item.name ?? location.locality ?? "Selected Location",
                    subtitle: location.formattedAddress,
                    coordinate: item.placemark.coordinate,
                    location: location
                )
            }
        } catch {
            results = []
            errorMessage = "Place search is unavailable right now. You can still tap the map to pick a pin."
        }
    }

    func selectSearchResult(_ result: LocationSearchResult) {
        selectedCoordinate = result.coordinate
        selectedLocation = result.location
        errorMessage = nil
    }

    func reverseGeocodeSelectedCoordinate() async {
        reverseGeocodeTask?.cancel()
        let coordinate = selectedCoordinate

        reverseGeocodeTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else {
                return
            }
            await self?.reverseGeocode(coordinate)
        }
    }

    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async {
        do {
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let placemark = try await geocoder.reverseGeocodeLocation(location).first
            selectedLocation = Self.location(from: placemark, coordinate: coordinate)
            errorMessage = nil
        } catch {
            selectedLocation = CapturedLocation(
                coordinate: coordinate,
                horizontalAccuracy: 0,
                locality: "Selected Location",
                formattedAddress: nil
            )
            errorMessage = "Address could not be fetched, but the selected latitude and longitude will still be stamped."
        }
    }

    private static func location(from mapItem: MKMapItem) -> CapturedLocation {
        location(from: mapItem.placemark, coordinate: mapItem.placemark.coordinate, fallbackName: mapItem.name)
    }

    private static func location(
        from placemark: CLPlacemark?,
        coordinate: CLLocationCoordinate2D,
        fallbackName: String? = nil
    ) -> CapturedLocation {
        let locality = firstNonEmpty(
            fallbackName,
            placemark?.name,
            placemark?.locality,
            placemark?.subLocality
        )
        let address = [
            placemark?.name,
            placemark?.subLocality,
            placemark?.locality,
            placemark?.administrativeArea,
            placemark?.postalCode,
            placemark?.country
        ]
            .compactMap { trimmed($0) }
            .removingDuplicates()
            .joined(separator: ", ")

        return CapturedLocation(
            coordinate: coordinate,
            horizontalAccuracy: 0,
            locality: locality,
            formattedAddress: address.isEmpty ? locality : address
        )
    }

    private static func firstNonEmpty(_ values: String?...) -> String? {
        values.lazy.compactMap { trimmed($0) }.first
    }

    private static func trimmed(_ value: String?) -> String? {
        let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue?.isEmpty == false ? trimmedValue : nil
    }
}

private struct MapCoordinatePicker: UIViewRepresentable {
    @Binding var selectedCoordinate: CLLocationCoordinate2D
    let selectedTitle: String

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.pointOfInterestFilter = .includingAll
        mapView.showsCompass = true
        mapView.showsScale = true

        let region = MKCoordinateRegion(
            center: selectedCoordinate,
            latitudinalMeters: 4_000,
            longitudinalMeters: 4_000
        )
        mapView.setRegion(region, animated: false)

        let tapRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapRecognizer)
        context.coordinator.updateAnnotation(on: mapView, coordinate: selectedCoordinate, title: selectedTitle)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.updateAnnotation(on: mapView, coordinate: selectedCoordinate, title: selectedTitle)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapCoordinatePicker
        private var annotation: MKPointAnnotation?

        init(parent: MapCoordinatePicker) {
            self.parent = parent
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let mapView = recognizer.view as? MKMapView else {
                return
            }
            let point = recognizer.location(in: mapView)
            parent.selectedCoordinate = mapView.convert(point, toCoordinateFrom: mapView)
        }

        func updateAnnotation(on mapView: MKMapView, coordinate: CLLocationCoordinate2D, title: String) {
            let pin = annotation ?? MKPointAnnotation()
            pin.coordinate = coordinate
            pin.title = title

            if annotation == nil {
                annotation = pin
                mapView.addAnnotation(pin)
            }

            let visibleMapRect = mapView.visibleMapRect
            let selectedPoint = MKMapPoint(coordinate)
            if !visibleMapRect.contains(selectedPoint) {
                mapView.setCenter(coordinate, animated: true)
            }
        }
    }
}

private extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

private struct StampFontSizeSlider: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value))")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            Slider(value: $value, in: 30...82, step: 1)
        }
        .padding(.vertical, 4)
    }
}

private struct StampMapSizeSlider: View {
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Map size")
                Spacer()
                Text("\(Int(value * 100))%")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            Slider(value: $value, in: 0.65...1.45, step: 0.05)
        }
        .padding(.vertical, 4)
    }
}
