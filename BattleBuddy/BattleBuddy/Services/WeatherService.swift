//
//  WeatherService.swift
//  BattleBuddy
//
//  Weather data integration using OpenWeather API
//

import Foundation
import CoreLocation
import Combine

class WeatherService: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var currentWeather: WeatherData?
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined

    // MARK: - Configuration
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"
    private var apiKey: String? {
        // User can add OpenWeather API key to Keychain
        KeychainHelper.shared.retrieve(forKey: "openweather_api_key")
    }

    // MARK: - Location Manager
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        checkLocationAuthorization()
    }

    // MARK: - Location Authorization
    func checkLocationAuthorization() {
        locationPermissionStatus = locationManager.authorizationStatus
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - Fetch Weather
    func fetchWeather() async -> WeatherData? {
        await MainActor.run {
            self.isLoading = true
            self.lastError = nil
        }

        // Check for API key
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            await handleError("No weather API key found. Add your OpenWeather API key in Settings.")
            return nil
        }

        // Get location
        guard let location = await getCurrentLocation() else {
            await handleError("Unable to get location. Please enable location services.")
            return nil
        }

        // Build URL
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(location.coordinate.latitude)),
            URLQueryItem(name: "lon", value: String(location.coordinate.longitude)),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "imperial") // Fahrenheit
        ]

        guard let url = components?.url else {
            await handleError("Invalid weather API URL")
            return nil
        }

        // Fetch data
        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                await handleError("Invalid response from weather API")
                return nil
            }

            if httpResponse.statusCode == 401 {
                await handleError("Invalid weather API key. Check your OpenWeather API key in Settings.")
                return nil
            }

            if httpResponse.statusCode != 200 {
                await handleError("Weather API error: HTTP \(httpResponse.statusCode)")
                return nil
            }

            // Parse response
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let weatherResponse = try decoder.decode(OpenWeatherResponse.self, from: data)

            let weatherData = WeatherData(
                temperature: weatherResponse.main.temp,
                feelsLike: weatherResponse.main.feelsLike,
                condition: weatherResponse.weather.first?.main ?? "Unknown",
                description: weatherResponse.weather.first?.description.capitalized ?? "No description",
                humidity: weatherResponse.main.humidity,
                windSpeed: weatherResponse.wind.speed,
                cityName: weatherResponse.name,
                timestamp: Date()
            )

            await MainActor.run {
                self.currentWeather = weatherData
                self.isLoading = false
            }

            return weatherData

        } catch {
            await handleError("Failed to fetch weather: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Get Current Location
    private func getCurrentLocation() async -> CLLocation? {
        // Check authorization
        let status = locationManager.authorizationStatus

        if status == .denied || status == .restricted {
            return nil
        }

        if status == .notDetermined {
            requestLocationPermission()
            return nil
        }

        // Request location
        return await withCheckedContinuation { continuation in
            locationManager.requestLocation()

            // Set timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if let location = self.currentLocation {
                    continuation.resume(returning: location)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    // MARK: - Weather Summary for Brief
    func getWeatherSummary() -> String {
        guard let weather = currentWeather else {
            return "Weather data unavailable"
        }

        let temp = Int(weather.temperature)
        let condition = weather.description

        // Add weather emoji
        let emoji = weatherEmoji(for: weather.condition)

        return "\(emoji) \(temp)°F and \(condition)"
    }

    private func weatherEmoji(for condition: String) -> String {
        switch condition.lowercased() {
        case "clear":
            return "☀️"
        case "clouds":
            return "☁️"
        case "rain", "drizzle":
            return "🌧️"
        case "thunderstorm":
            return "⛈️"
        case "snow":
            return "❄️"
        case "mist", "fog", "haze":
            return "🌫️"
        default:
            return "🌤️"
        }
    }

    // MARK: - Error Handling
    private func handleError(_ message: String) async {
        await MainActor.run {
            self.lastError = message
            self.isLoading = false
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension WeatherService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.first
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.locationPermissionStatus = manager.authorizationStatus
        }
    }
}

// MARK: - Weather Data Model
struct WeatherData: Codable {
    let temperature: Double
    let feelsLike: Double
    let condition: String
    let description: String
    let humidity: Int
    let windSpeed: Double
    let cityName: String
    let timestamp: Date

    var temperatureString: String {
        "\(Int(temperature))°F"
    }

    var feelsLikeString: String {
        "Feels like \(Int(feelsLike))°F"
    }
}

// MARK: - OpenWeather API Response
struct OpenWeatherResponse: Codable {
    let name: String
    let main: MainWeather
    let weather: [Weather]
    let wind: Wind

    struct MainWeather: Codable {
        let temp: Double
        let feelsLike: Double
        let humidity: Int
    }

    struct Weather: Codable {
        let main: String
        let description: String
    }

    struct Wind: Codable {
        let speed: Double
    }
}
