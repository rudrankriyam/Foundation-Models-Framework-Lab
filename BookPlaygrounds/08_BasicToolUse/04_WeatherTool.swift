//
//  04_WeatherTool.swift
//  Exploring Foundation Models
//
//  Created by Rudrank Riyam on 9/24/25.
//

import Foundation
import FoundationModels
import Playgrounds

struct WeatherTool: Tool {
    let name = "getCurrentWeather"
    let description = "Gets live weather conditions for a city from Open-Meteo"

    @Generable
    struct Arguments {
        @Guide(description: "The city name to get weather for")
        var city: String

        @Guide(description: "An optional ISO 3166-1 alpha-2 country code, such as US or GB")
        var countryCode: String?
    }

    @Generable
    struct WeatherData {
        let city: String
        let country: String
        let temperature: Double
        let feelsLike: Double
        let humidity: Int
        let conditions: String
        let description: String
        let windSpeed: Double
    }

    func call(arguments: Arguments) async throws -> WeatherData {
        let city = arguments.city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !city.isEmpty else {
            throw WeatherError.emptyCity
        }

        let place = try await geocode(city: city, countryCode: arguments.countryCode)
        let conditions = try await currentConditions(
            latitude: place.latitude,
            longitude: place.longitude
        )
        let description = weatherDescription(for: conditions.weatherCode)

        return WeatherData(
            city: place.name,
            country: place.country ?? place.countryCode ?? "Unknown",
            temperature: conditions.temperature,
            feelsLike: conditions.apparentTemperature,
            humidity: conditions.relativeHumidity,
            conditions: description.title,
            description: description.detail,
            windSpeed: conditions.windSpeed
        )
    }

    private func geocode(city: String, countryCode: String?) async throws -> GeocodingResult {
        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")
        components?.queryItems = [
            URLQueryItem(name: "name", value: city),
            URLQueryItem(name: "count", value: "1"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]
        if let countryCode = countryCode?.trimmingCharacters(in: .whitespacesAndNewlines),
           !countryCode.isEmpty {
            components?.queryItems?.append(
                URLQueryItem(name: "countryCode", value: countryCode.uppercased())
            )
        }

        let response: GeocodingResponse = try await fetch(components?.url)
        guard let result = response.results?.first else {
            throw WeatherError.cityNotFound(city)
        }
        return result
    }

    private func currentConditions(latitude: Double, longitude: Double) async throws -> CurrentWeather {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(
                name: "current",
                value: "temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m"
            ),
            URLQueryItem(name: "temperature_unit", value: "celsius"),
            URLQueryItem(name: "wind_speed_unit", value: "kmh"),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        let response: WeatherResponse = try await fetch(components?.url)
        return response.current
    }

    private func fetch<Response: Decodable & Sendable>(_ url: URL?) async throws -> Response {
        guard let url else {
            throw WeatherError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw WeatherError.invalidResponse
        }
        return try JSONDecoder().decode(Response.self, from: data)
    }

    private func weatherDescription(for code: Int) -> (title: String, detail: String) {
        switch code {
        case 0:
            return ("Clear", "Clear sky")
        case 1...3:
            return ("Cloudy", "Mainly clear to overcast")
        case 45, 48:
            return ("Fog", "Foggy conditions")
        case 51...67, 80...82:
            return ("Rain", "Drizzle or rain showers")
        case 71...77, 85, 86:
            return ("Snow", "Snowfall or snow showers")
        case 95...99:
            return ("Thunderstorm", "Thunderstorms are reported")
        default:
            return ("Unknown", "Open-Meteo weather code \(code)")
        }
    }
}

nonisolated private struct GeocodingResponse: Decodable, Sendable {
    let results: [GeocodingResult]?
}

nonisolated private struct GeocodingResult: Decodable, Sendable {
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String?
    let countryCode: String?

    enum CodingKeys: String, CodingKey {
        case name, latitude, longitude, country
        case countryCode = "country_code"
    }
}

nonisolated private struct WeatherResponse: Decodable, Sendable {
    let current: CurrentWeather
}

nonisolated private struct CurrentWeather: Decodable, Sendable {
    let temperature: Double
    let relativeHumidity: Int
    let apparentTemperature: Double
    let weatherCode: Int
    let windSpeed: Double

    enum CodingKeys: String, CodingKey {
        case temperature = "temperature_2m"
        case relativeHumidity = "relative_humidity_2m"
        case apparentTemperature = "apparent_temperature"
        case weatherCode = "weather_code"
        case windSpeed = "wind_speed_10m"
    }
}

private enum WeatherError: LocalizedError {
    case emptyCity
    case cityNotFound(String)
    case invalidURL
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .emptyCity:
            return "City name cannot be empty."
        case .cityNotFound(let city):
            return "Open-Meteo could not find \(city)."
        case .invalidURL:
            return "The Open-Meteo URL could not be created."
        case .invalidResponse:
            return "Open-Meteo returned an invalid response."
        }
    }
}

#Playground {
    let weatherTool = WeatherTool()
    let arguments = WeatherTool.Arguments(city: "San Francisco", countryCode: "US")
    let result = try await weatherTool.call(arguments: arguments)
    debugPrint("Weather result: \(result)")
}
