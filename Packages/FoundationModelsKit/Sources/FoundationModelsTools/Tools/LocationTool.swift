//
//  LocationTool.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/17/25.
//

@preconcurrency import CoreLocation
import Foundation
import FoundationModels
import FoundationModelsKit
@preconcurrency import MapKit

/// A tool for location services and geocoding using CoreLocation and MapKit.
///
/// Use `LocationTool` to access current location, geocoding, reverse geocoding,
/// place search, and distance calculations between coordinates.
///
/// The following actions are supported:
/// - `current`: Get the device's current location
/// - `geocode`: Convert an address to coordinates
/// - `reverse`: Convert coordinates to an address
/// - `search`: Search for nearby places
/// - `distance`: Calculate distance between two coordinate pairs
///
/// ```swift
/// let session = LanguageModelSession(tools: [LocationTool()])
/// let response = try await session.respond(to: "Where is Apple Park located?")
/// ```
///
/// - Important: Requires Location Services capability, `NSLocationWhenInUseUsageDescription`
///   in Info.plist, and user permission at runtime.
public struct LocationTool: Tool {

  /// The name of the tool, used for identification.
  public let name = "accessLocation"
  /// A brief description of the tool's functionality.
  public let description =
    "Get current location, geocode addresses, search places, and calculate distances"

  /// Arguments for location operations.
  @Generable
  public struct Arguments: RuntimeCompatibleGenerable {
    /// The action to perform: "current", "geocode", "reverse", "search", "distance"
    @Guide(
      description: "The action to perform: 'current', 'geocode', 'reverse', 'search', 'distance'")
    public var action: String

    /// Address to geocode (for geocode action)
    @Guide(description: "Address to geocode (for geocode action)")
    public var address: String?

    /// Latitude for reverse geocoding or distance calculation
    @Guide(description: "Latitude for reverse geocoding or distance calculation")
    public var latitude: Double?

    /// Longitude for reverse geocoding or distance calculation
    @Guide(description: "Longitude for reverse geocoding or distance calculation")
    public var longitude: Double?

    /// Second latitude for distance calculation
    @Guide(description: "Second latitude for distance calculation")
    public var latitude2: Double?

    /// Second longitude for distance calculation
    @Guide(description: "Second longitude for distance calculation")
    public var longitude2: Double?

    /// Search query for places (for search action)
    @Guide(description: "Search query for places (for search action)")
    public var searchQuery: String?

    /// Search radius in meters (defaults to 1000)
    @Guide(description: "Search radius in meters (defaults to 1000)")
    public var radius: Double?

    public init(
      action: String = "",
      address: String? = nil,
      latitude: Double? = nil,
      longitude: Double? = nil,
      latitude2: Double? = nil,
      longitude2: Double? = nil,
      searchQuery: String? = nil,
      radius: Double? = nil
    ) {
      self.action = action
      self.address = address
      self.latitude = latitude
      self.longitude = longitude
      self.latitude2 = latitude2
      self.longitude2 = longitude2
      self.searchQuery = searchQuery
      self.radius = radius
    }
  }

  private let locationManager = CLLocationManager()

  public init() {
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.distanceFilter = kCLDistanceFilterNone
  }

  public func call(arguments: Arguments) async throws -> some PromptRepresentable {
    switch arguments.action.lowercased() {
    case "current":
      return await getCurrentLocation()
    case "geocode":
      return await geocodeAddress(address: arguments.address)
    case "reverse":
      return await reverseGeocode(latitude: arguments.latitude, longitude: arguments.longitude)
    case "search":
      return await searchPlaces(query: arguments.searchQuery, radius: arguments.radius)
    case "distance":
      return calculateDistance(arguments: arguments)
    default:
      return createErrorOutput(error: LocationError.invalidAction)
    }
  }

  private func getCurrentLocation() async -> GeneratedContent {
    let authorization = await checkLocationAuthorization()

    if !authorization.isAuthorized {
      if authorization.status == .notDetermined {
        return await requestLocationPermission()
      }

      if let message = authorization.result {
        return message
      }

      return createErrorOutput(error: LocationError.authorizationDenied)
    }

    do {
      let location = try await requestLiveLocation()
      return await buildCurrentLocationContent(from: location, source: .live)
    } catch {
      if let cached = await cachedLocation() {
        return await buildCurrentLocationContent(from: cached, source: .cached)
      }

      if let locationError = error as? LocationError {
        return createErrorOutput(error: locationError)
      }

      return createErrorOutput(error: error)
    }
  }

  @MainActor
  private func cachedLocation() -> CLLocation? {
    locationManager.location
  }

  @MainActor
  private func requestLiveLocation(timeout: TimeInterval = 8) async throws -> CLLocation {
    let fetcher = CurrentLocationFetcher()
    return try await fetcher.requestLocation(using: locationManager, timeout: timeout)
  }

  private func buildCurrentLocationContent(
    from location: CLLocation,
    source: LocationResultSource
  ) async -> GeneratedContent {
    let mapItem = await reverseGeocode(location: location)
    let address = formatAddress(from: mapItem, fallbackLocation: location)

    return GeneratedContent(properties: [
      "status": "success",
      "source": source.identifier,
      "latitude": location.coordinate.latitude,
      "longitude": location.coordinate.longitude,
      "altitude": location.altitude,
      "accuracy": location.horizontalAccuracy,
      "timestamp": formatDate(location.timestamp),
      "address": address,
      "message": source.message(for: address),
      "note": source.note ?? ""
    ])
  }

  private func reverseGeocode(location: CLLocation) async -> MKMapItem? {
    guard let request = MKReverseGeocodingRequest(location: location) else {
      return nil
    }

    return try? await request.mapItems.first
  }

  private func geocodeAddress(address: String?) async -> GeneratedContent {
    guard let address = address, !address.isEmpty else {
      return createErrorOutput(error: LocationError.missingAddress)
    }

    do {
      guard let request = MKGeocodingRequest(addressString: address) else {
        return createErrorOutput(error: LocationError.geocodingFailed)
      }

      let mapItems = try await request.mapItems
      guard let mapItem = mapItems.first else {
        return createErrorOutput(error: LocationError.geocodingFailed)
      }

      let formattedAddress = formatAddress(from: mapItem, fallbackLocation: mapItem.location)
      let location = mapItem.location

      return GeneratedContent(properties: [
        "status": "success",
        "query": address,
        "latitude": location.coordinate.latitude,
        "longitude": location.coordinate.longitude,
        "formattedAddress": formattedAddress,
        "message": "Location found: \(formattedAddress)"
      ])
    } catch {
      return createErrorOutput(error: error)
    }
  }

  private func reverseGeocode(latitude: Double?, longitude: Double?) async -> GeneratedContent {
    guard let latitude = latitude,
      let longitude = longitude
    else {
      return createErrorOutput(error: LocationError.missingCoordinates)
    }

    let location = CLLocation(latitude: latitude, longitude: longitude)

    do {
      guard let request = MKReverseGeocodingRequest(location: location) else {
        return createErrorOutput(error: LocationError.reverseGeocodingFailed)
      }
      let mapItems = try await request.mapItems

      guard let mapItem = mapItems.first else {
        return createErrorOutput(error: LocationError.reverseGeocodingFailed)
      }

      let address = formatAddress(from: mapItem, fallbackLocation: location)

      return GeneratedContent(properties: [
        "status": "success",
        "latitude": latitude,
        "longitude": longitude,
        "address": address,
        "message": "Address: \(address)"
      ])
    } catch {
      return createErrorOutput(error: error)
    }
  }

  private func searchPlaces(query: String?, radius: Double?) async -> GeneratedContent {
    guard let query = query, !query.isEmpty else {
      return createErrorOutput(error: LocationError.missingSearchQuery)
    }

    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = query

    // Set search region if we have current location
    if let location = locationManager.location {
      let searchRadius = radius ?? 1000  // Default 1km
      request.region = MKCoordinateRegion(
        center: location.coordinate,
        latitudinalMeters: searchRadius * 2,
        longitudinalMeters: searchRadius * 2
      )
    }

    let search = MKLocalSearch(request: request)

    do {
      let response = try await search.start()

      var placesDescription = ""

      for (index, item) in response.mapItems.prefix(10).enumerated() {
        let distance: String
        if let userLocation = locationManager.location {
          let placeLocation = CLLocation(
            latitude: item.location.coordinate.latitude,
            longitude: item.location.coordinate.longitude
          )
          let meters = userLocation.distance(from: placeLocation)
          distance = formatDistance(meters)
        } else {
          distance = "Unknown distance"
        }

        placesDescription += "\(index + 1). \(item.name ?? "Unknown Place")\n"
        placesDescription += "   Address: \(formatMapItemAddress(item))\n"
        placesDescription += "   Distance: \(distance)\n"
        if let phone = item.phoneNumber {
          placesDescription += "   Phone: \(phone)\n"
        }
        placesDescription += "\n"
      }

      if placesDescription.isEmpty {
        placesDescription = "No places found matching '\(query)'"
      }

      return GeneratedContent(properties: [
        "status": "success",
        "query": query,
        "resultCount": response.mapItems.count,
        "places": placesDescription.trimmingCharacters(in: .whitespacesAndNewlines),
        "message": "Found \(response.mapItems.count) place(s)"
      ])
    } catch {
      return createErrorOutput(error: error)
    }
  }

  private func calculateDistance(arguments: Arguments) -> GeneratedContent {
    guard let lat1 = arguments.latitude,
      let lon1 = arguments.longitude,
      let lat2 = arguments.latitude2,
      let lon2 = arguments.longitude2
    else {
      return createErrorOutput(error: LocationError.missingCoordinates)
    }

    let location1 = CLLocation(latitude: lat1, longitude: lon1)
    let location2 = CLLocation(latitude: lat2, longitude: lon2)

    let distance = location1.distance(from: location2)

    // Calculate bearing
    let bearing = calculateBearing(from: location1, to: location2)
    let direction = compassDirection(from: bearing)

    return GeneratedContent(properties: [
      "status": "success",
      "location1_latitude": lat1,
      "location1_longitude": lon1,
      "location2_latitude": lat2,
      "location2_longitude": lon2,
      "distanceMeters": distance,
      "distanceKilometers": distance / 1000,
      "distanceMiles": distance / 1609.344,
      "formattedDistance": formatDistance(distance),
      "bearing": bearing,
      "direction": direction,
      "message": "Distance: \(formatDistance(distance)) \(direction)"
    ])
  }

  private func formatMapItemAddress(_ mapItem: MKMapItem?) -> String {
    formatAddress(from: mapItem, fallbackLocation: mapItem?.location)
  }

  private func formatDistance(_ meters: Double) -> String {
    if meters < 1000 {
      return String(format: "%.0f meters", meters)
    } else if meters < 10000 {
      return String(format: "%.1f km", meters / 1000)
    } else {
      return String(format: "%.0f km", meters / 1000)
    }
  }

  private func calculateBearing(from: CLLocation, to: CLLocation) -> Double {
    let lat1 = from.coordinate.latitude.degreesToRadians
    let lon1 = from.coordinate.longitude.degreesToRadians
    let lat2 = to.coordinate.latitude.degreesToRadians
    let lon2 = to.coordinate.longitude.degreesToRadians

    let dLon = lon2 - lon1

    let y = sin(dLon) * cos(lat2)
    let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)

    let radiansBearing = atan2(y, x)
    let degreesBearing = radiansBearing.radiansToDegrees

    return (degreesBearing + 360).truncatingRemainder(dividingBy: 360)
  }

  private func compassDirection(from bearing: Double) -> String {
    let directions = [
      "N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
      "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"
    ]
    let index = Int((bearing + 11.25) / 22.5) % 16
    return directions[index]
  }

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .medium
    return formatter.string(from: date)
  }

  @MainActor
  private func requestLocationPermission() async -> GeneratedContent {
    let permissionRequester = PermissionRequester()
    let receivedResponse = await permissionRequester.requestAuthorization(using: locationManager)

    guard receivedResponse else {
      return createErrorOutput(error: LocationError.authorizationNotDetermined)
    }

    // Check the new authorization status
    let authorization = await checkLocationAuthorization()
    if authorization.isAuthorized {
      // Permission granted, try to get location
      return await getCurrentLocation()
    } else {
      return createErrorOutput(error: LocationError.authorizationDenied)
    }
  }

  private func createErrorOutput(error: Error) -> GeneratedContent {
    return GeneratedContent(properties: [
      "status": "error",
      "error": error.localizedDescription,
      "message": "Failed to perform location operation"
    ])
  }

  /// Checks if location authorization is sufficient for the current platform
  private func checkLocationAuthorization() async -> AuthorizationResult {
    let status = await MainActor.run { locationManager.authorizationStatus }
    let servicesEnabled = await Task(priority: .userInitiated) {
      CLLocationManager.locationServicesEnabled()
    }.value

    guard servicesEnabled else {
      return AuthorizationResult(
        status: status,
        isAuthorized: false,
        result: createErrorOutput(error: LocationError.locationServicesDisabled)
      )
    }

    #if os(iOS) || os(visionOS)
      if status == .authorizedAlways || status == .authorizedWhenInUse {
        return AuthorizationResult(status: status, isAuthorized: true, result: nil)
      }
    #elseif os(macOS)
      if status == .authorizedAlways {
        return AuthorizationResult(status: status, isAuthorized: true, result: nil)
      }
    #else
      if status == .authorizedAlways || status == .authorizedWhenInUse {
        return AuthorizationResult(status: status, isAuthorized: true, result: nil)
      }
    #endif

    if status == .notDetermined {
      return AuthorizationResult(status: status, isAuthorized: false, result: nil)
    }

    return AuthorizationResult(
      status: status,
      isAuthorized: false,
      result: createErrorOutput(error: LocationError.authorizationDenied)
    )
  }
}

private struct AuthorizationResult {
  let status: CLAuthorizationStatus
  let isAuthorized: Bool
  let result: GeneratedContent?
}

private enum LocationResultSource {
  case live
  case cached

  func message(for address: String) -> String {
    switch self {
    case .live:
      return "Current location: \(address)"
    case .cached:
      return "Last known location: \(address)"
    }
  }

  var note: String? {
    switch self {
    case .live:
      return nil
    case .cached:
      return "Using last known location while waiting for a precise update."
    }
  }

  var identifier: String {
    switch self {
    case .live:
      return "live"
    case .cached:
      return "cached"
    }
  }
}

// AddressDetails struct removed - now using String directly

@MainActor
final class CurrentLocationFetcher: NSObject, @MainActor CLLocationManagerDelegate {
  private var continuation: CheckedContinuation<CLLocation, Error>?
  private var timeoutTask: Task<Void, Never>?

  @MainActor
  func requestLocation(
    using manager: CLLocationManager,
    timeout: TimeInterval = 8
  ) async throws -> CLLocation {
    if continuation != nil {
      throw LocationError.operationInProgress
    }

    return try await withCheckedThrowingContinuation { continuation in
      self.continuation = continuation
      manager.delegate = self

      #if os(macOS)
        manager.startUpdatingLocation()
      #else
        manager.requestLocation()
      #endif

      timeoutTask = Task { [weak self, weak manager] in
        do {
          try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
          guard let self, let manager else { return }
          self.handleTimeout(manager: manager)
        } catch {
          // Task cancelled; cleanup already handled elsewhere.
        }
      }
    }
  }

  @MainActor
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }
    if let continuation = cleanup(manager: manager) {
      continuation.resume(returning: location)
    }
  }

  @MainActor
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    if let continuation = cleanup(manager: manager) {
      continuation.resume(throwing: error)
    }
  }

  @MainActor
  private func handleTimeout(manager: CLLocationManager) {
    guard let continuation = cleanup(manager: manager) else { return }
    continuation.resume(throwing: LocationError.locationTimeout)
  }

  @MainActor
  private func cleanup(manager: CLLocationManager)
    -> CheckedContinuation<CLLocation, Error>? {
    timeoutTask?.cancel()
    timeoutTask = nil
    #if os(macOS)
      manager.stopUpdatingLocation()
    #endif
    manager.delegate = nil
    let continuation = self.continuation
    self.continuation = nil
    return continuation
  }
}

private func formatAddress(
  from mapItem: MKMapItem?,
  fallbackLocation: CLLocation?
) -> String {
  guard let mapItem else {
    return fallbackLocation.map(coordinateDescription) ?? "Unknown location"
  }

  // Use the new MKAddress instead of deprecated placemark
  return mapItem.address?.fullAddress ?? mapItem.name ?? "Unknown location"
}

private func coordinateDescription(for location: CLLocation) -> String {
  String(
    format: "%.4f, %.4f",
    location.coordinate.latitude,
    location.coordinate.longitude
  )
}

extension Double {
  var degreesToRadians: Double { self * .pi / 180 }
  var radiansToDegrees: Double { self * 180 / .pi }
}

enum LocationError: Error, LocalizedError {
  case invalidAction
  case authorizationDenied
  case authorizationNotDetermined
  case locationServicesDisabled
  case locationUnavailable
  case locationTimeout
  case operationInProgress
  case missingAddress
  case missingCoordinates
  case missingSearchQuery
  case geocodingFailed
  case reverseGeocodingFailed

  var errorDescription: String? {
    switch self {
    case .invalidAction:
      return "Invalid action. Use 'current', 'geocode', 'reverse', 'search', or 'distance'."
    case .authorizationDenied:
      return "Location access denied. Please grant permission in Settings."
    case .authorizationNotDetermined:
      return "Location permission not yet determined. Please grant permission when prompted."
    case .locationServicesDisabled:
      return "Location services are disabled. Enable Location Services to continue."
    case .locationUnavailable:
      return "Current location is unavailable."
    case .locationTimeout:
      return "Timed out while waiting for an updated location."
    case .operationInProgress:
      return "A location request is already in progress."
    case .missingAddress:
      return "Address is required for geocoding."
    case .missingCoordinates:
      return "Latitude and longitude are required."
    case .missingSearchQuery:
      return "Search query is required."
    case .geocodingFailed:
      return "Failed to find location for the given address."
    case .reverseGeocodingFailed:
      return "Failed to find address for the given coordinates."
    }
  }
}

@MainActor
final class PermissionRequester: NSObject, CLLocationManagerDelegate {
  private var continuation: CheckedContinuation<Bool, Never>?
  private var timeoutTask: Task<Void, Never>?

  func requestAuthorization(
    using manager: CLLocationManager,
    timeout: TimeInterval = 8
  ) async -> Bool {
    guard manager.authorizationStatus == .notDetermined else {
      return true
    }

    return await withCheckedContinuation { continuation in
      self.continuation = continuation
      manager.delegate = self
      manager.requestWhenInUseAuthorization()
      #if os(macOS)
        manager.startUpdatingLocation()
      #endif

      timeoutTask = Task { @MainActor [weak self] in
        do {
          try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
          self?.finish(receivedResponse: false, manager: manager)
        } catch {
          // Task cancelled after receiving an authorization response.
        }
      }
    }
  }

  nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    Task { @MainActor [weak self] in
      guard manager.authorizationStatus != .notDetermined else { return }
      self?.finish(receivedResponse: true, manager: manager)
    }
  }

  private func finish(receivedResponse: Bool, manager: CLLocationManager) {
    guard let continuation else { return }
    timeoutTask?.cancel()
    timeoutTask = nil
    #if os(macOS)
      manager.stopUpdatingLocation()
    #endif
    manager.delegate = nil
    self.continuation = nil
    continuation.resume(returning: receivedResponse)
  }
}
