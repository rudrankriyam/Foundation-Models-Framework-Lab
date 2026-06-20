//
//  05_LocationTool.swift
//  Exploring Foundation Models
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import CoreLocation
import Foundation
import FoundationModels
import MapKit
import Playgrounds

struct LocationTool: Tool {
    let name = "getUserLocation"
    let description = "Gets the user's current location after Core Location grants permission"

    @Generable
    struct Arguments {
        @Guide(description: "Whether to reverse-geocode city and country information")
        var includeAddress: Bool = false
    }

    @Generable
    struct LocationData {
        let latitude: Double
        let longitude: Double
        let city: String?
        let country: String?
        let timestamp: String
    }

    func call(arguments: Arguments) async throws -> LocationData {
        let location = try await CurrentLocationProvider.requestLocation()
        var city: String?
        var country: String?

        if arguments.includeAddress,
           let request = MKReverseGeocodingRequest(location: location),
           let mapItems = try? await request.mapItems,
           let address = mapItems.first?.addressRepresentations {
            city = address.cityName
            country = address.regionName
        }

        return LocationData(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            city: city,
            country: country,
            timestamp: ISO8601DateFormatter().string(from: location.timestamp)
        )
    }
}

@MainActor
private final class CurrentLocationProvider: NSObject, @MainActor CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?

    static func requestLocation() async throws -> CLLocation {
        let provider = CurrentLocationProvider()
        return try await provider.requestLocation()
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    private func requestLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            requestAuthorizationOrLocation()
        }
    }

    private func requestAuthorizationOrLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            finish(with: .failure(LocationError.permissionDenied))
        @unknown default:
            finish(with: .failure(LocationError.permissionDenied))
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard continuation != nil else { return }
        requestAuthorizationOrLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            finish(with: .failure(LocationError.locationUnavailable))
            return
        }
        finish(with: .success(location))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(with: .failure(error))
    }

    private func finish(with result: Result<CLLocation, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(with: result)
    }
}

private enum LocationError: LocalizedError {
    case permissionDenied
    case locationUnavailable

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission is required for this tool."
        case .locationUnavailable:
            return "Core Location did not return a location."
        }
    }
}

#Playground {
    let locationTool = LocationTool()
    let arguments = LocationTool.Arguments(includeAddress: true)
    let result = try await locationTool.call(arguments: arguments)
    debugPrint("Location result: \(result)")
}
