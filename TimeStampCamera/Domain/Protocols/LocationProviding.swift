@MainActor
protocol LocationProviding {
    func currentLocation() async throws -> CapturedLocation
}
