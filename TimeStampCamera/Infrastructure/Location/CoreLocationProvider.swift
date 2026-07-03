import CoreLocation
import Foundation

@MainActor
final class CoreLocationProvider: NSObject, LocationProviding {
    private let locationManager: CLLocationManager
    private let geocoder: CLGeocoder
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?

    init(
        locationManager: CLLocationManager = CLLocationManager(),
        geocoder: CLGeocoder = CLGeocoder()
    ) {
        self.locationManager = locationManager
        self.geocoder = geocoder
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func currentLocation() async throws -> CapturedLocation {
        let authorization = await resolvedAuthorizationStatus()

        guard authorization != .denied && authorization != .restricted else {
            throw LocationProviderError.permissionDenied
        }

        let location = try await requestOneShotLocation()
        let placemark = try? await geocoder.reverseGeocodeLocation(location).first
        let address = [placemark?.name, placemark?.locality, placemark?.administrativeArea, placemark?.country]
            .compactMap { $0 }
            .joined(separator: ", ")

        return CapturedLocation(
            coordinate: location.coordinate,
            horizontalAccuracy: location.horizontalAccuracy,
            locality: placemark?.locality,
            formattedAddress: address.isEmpty ? nil : address
        )
    }

    private func resolvedAuthorizationStatus() async -> CLAuthorizationStatus {
        let authorization = locationManager.authorizationStatus
        guard authorization == .notDetermined else {
            return authorization
        }

        return await withCheckedContinuation { continuation in
            authorizationContinuation = continuation
            locationManager.requestWhenInUseAuthorization()
        }
    }

    private func requestOneShotLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            if let locationContinuation {
                locationContinuation.resume(throwing: LocationProviderError.locationRequestAlreadyInFlight)
            }
            self.locationContinuation = continuation
            locationManager.requestLocation()
        }
    }
}

extension CoreLocationProvider: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            guard manager.authorizationStatus != .notDetermined else {
                return
            }
            authorizationContinuation?.resume(returning: manager.authorizationStatus)
            authorizationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else {
                locationContinuation?.resume(throwing: LocationProviderError.locationUnavailable)
                locationContinuation = nil
                return
            }
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            locationContinuation?.resume(throwing: error)
            locationContinuation = nil
        }
    }
}

enum LocationProviderError: LocalizedError {
    case permissionDenied
    case locationUnavailable
    case locationRequestAlreadyInFlight

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "Location permission is required to stamp where the photo was taken."
        case .locationUnavailable:
            "Current location could not be found."
        case .locationRequestAlreadyInFlight:
            "A location request is already in progress."
        }
    }
}
