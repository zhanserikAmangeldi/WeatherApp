import Foundation
import CoreLocation
import Combine
import SwiftUI

@MainActor
class WeatherViewModel: ObservableObject {
    private let locationManager = LocationManager()
    @Published var currentLocation: CLLocation?
    @Published var locationName: String = "Loading location..."
    
    @Published var currentWeatherState: LoadingState<CurrentWeather> = .idle
    @Published var forecastState: LoadingState<ForecastResponse> = .idle
    @Published var airQualityState: LoadingState<AirQualityResponse> = .idle
    @Published var alertsState: LoadingState<AlertsResponse> = .idle
    @Published var selectedMapLayer: APIService.WeatherMapLayer = .precipitation
    @Published var mapURL: URL?
    
    private var currentDataTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupLocationUpdates()
    }
    
    private func setupLocationUpdates() {
        locationManager.$location
            .compactMap { $0 }
            .removeDuplicates()
            .sink { [weak self] location in
                self?.currentLocation = location
                self?.updateLocationName(for: location)
                self?.fetchAllWeatherData(for: location.coordinate.latitude, longitude: location.coordinate.longitude)
            }
            .store(in: &cancellables)
        
        locationManager.$errorMessage
            .compactMap { $0 }
            .sink { [weak self] errorMessage in
                self?.handleLocationError(errorMessage)
            }
            .store(in: &cancellables)
    }
    
    private func updateLocationName(for location: CLLocation) {
        Task {
            do {
                locationName = try await locationManager.getPlaceName(for: location)
            } catch {
                locationName = "Unknown Location"
                print("Error getting location name: \(error)")
            }
        }
    }
    
    private func handleLocationError(_ errorMessage: String) {
        locationName = "Location Unavailable"
        
        let error = WeatherError.locationServicesDisabled
        currentWeatherState = .failure(error)
        forecastState = .failure(error)
        airQualityState = .failure(error)
        alertsState = .failure(error)
    }
        
    /// Fetch all weather data concurrently using structured concurrency
    func fetchAllWeatherData(for latitude: Double, longitude: Double) {
        cancelCurrentDataTask()
        
        currentWeatherState = .loading()
        forecastState = .loading()
        airQualityState = .loading()
        alertsState = .loading()
        
        currentDataTask = Task {
            await fetchDataConcurrently(lat: latitude, lon: longitude)
            
            updateWeatherMap(for: latitude, longitude: longitude)
        }
    }
    
    /// Cancel the current data fetch task if it exists
    func cancelCurrentDataTask() {
        currentDataTask?.cancel()
        currentDataTask = nil
    }
    
    /// Fetch weather data concurrently using TaskGroup
    private func fetchDataConcurrently(lat: Double, lon: Double) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.fetchCurrentWeather(lat: lat, lon: lon)
            }
            
            group.addTask {
                await self.fetchForecast(lat: lat, lon: lon)
            }
            
            group.addTask {
                await self.fetchAirQuality(lat: lat, lon: lon)
            }
            
            group.addTask {
                await self.fetchAlerts(lat: lat, lon: lon)
            }
            
            for await _ in group {}
        }
    }
    
    /// Fetch current weather data with caching
    private func fetchCurrentWeather(lat: Double, lon: Double) async {
        do {
            let cacheKey = CacheService.shared.cacheKey(for: .currentWeather(lat: lat, lon: lon))
            if let cachedData: CurrentWeather = CacheService.shared.retrieveData(for: cacheKey) {
                currentWeatherState = .success(cachedData)
                return
            }
            
            currentWeatherState = .loading(progress: 0.3)
            
            if ProcessInfo.processInfo.environment["PREVIEW"] == "true" {
                try await Task.sleep(nanoseconds: 1_500_000_000)
            }
            
            try Task.checkCancellation()
            
            currentWeatherState = .loading(progress: 0.7)
            
            let weather = try await APIService.shared.fetchCurrentWeather(lat: lat, lon: lon)
            
            try Task.checkCancellation()
            
            CacheService.shared.cacheData(weather, for: cacheKey)
            
            currentWeatherState = .success(weather)
        } catch is CancellationError {
            return
        } catch {
            currentWeatherState = .failure(error)
        }
    }
    
    /// Fetch forecast data with caching
    private func fetchForecast(lat: Double, lon: Double) async {
        do {
            let cacheKey = CacheService.shared.cacheKey(for: .forecast(lat: lat, lon: lon))
            if let cachedData: ForecastResponse = CacheService.shared.retrieveData(for: cacheKey) {
                forecastState = .success(cachedData)
                return
            }
            
            forecastState = .loading(progress: 0.3)
            
            if ProcessInfo.processInfo.environment["PREVIEW"] == "true" {
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            }
            
            try Task.checkCancellation()
            
            forecastState = .loading(progress: 0.7)
            
            let forecast = try await APIService.shared.fetchForecast(lat: lat, lon: lon)
            
            try Task.checkCancellation()
            
            CacheService.shared.cacheData(forecast, for: cacheKey)
            
            forecastState = .success(forecast)
        } catch is CancellationError {
            return
        } catch {
            forecastState = .failure(error)
        }
    }
    
    /// Fetch air quality data with caching
    private func fetchAirQuality(lat: Double, lon: Double) async {
        do {
            let cacheKey = CacheService.shared.cacheKey(for: .airQuality(lat: lat, lon: lon))
            if let cachedData: AirQualityResponse = CacheService.shared.retrieveData(for: cacheKey) {
                airQualityState = .success(cachedData)
                return
            }
            
            airQualityState = .loading(progress: 0.3)
            
            if ProcessInfo.processInfo.environment["PREVIEW"] == "true" {
                try await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
            }
            
            try Task.checkCancellation()
            
            airQualityState = .loading(progress: 0.7)
            
            let airQuality = try await APIService.shared.fetchAirQuality(lat: lat, lon: lon)
            
            try Task.checkCancellation()
            
            CacheService.shared.cacheData(airQuality, for: cacheKey)
            
            airQualityState = .success(airQuality)
        } catch is CancellationError {
            return
        } catch {
            airQualityState = .failure(error)
        }
    }
    
    /// Fetch alerts data with caching
    private func fetchAlerts(lat: Double, lon: Double) async {
        do {
            let cacheKey = CacheService.shared.cacheKey(for: .alerts(lat: lat, lon: lon))
            if let cachedData: AlertsResponse = CacheService.shared.retrieveData(for: cacheKey) {
                alertsState = .success(cachedData)
                return
            }
            
            alertsState = .loading(progress: 0.3)
            
            if ProcessInfo.processInfo.environment["PREVIEW"] == "true" {
                try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            }
            
            try Task.checkCancellation()
            
            alertsState = .loading(progress: 0.7)
            
            let alerts = try await APIService.shared.fetchAlerts(lat: lat, lon: lon)
            
            try Task.checkCancellation()
            
            CacheService.shared.cacheData(alerts, for: cacheKey)
            
            alertsState = .success(alerts)
        } catch is CancellationError {
            return
        } catch {
            alertsState = .failure(error)
        }
    }
    
    /// Update the weather map URL for the selected layer
    func updateWeatherMap(for latitude: Double, longitude: Double) {
        let zoom = 2
        
        // These calculations convert lat/lon to x,y tile coordinates using
        // the standard Web Mercator projection formula
        let n = pow(2.0, Double(zoom))
        
        // Ensure latitude is within valid range for Mercator projection (-85.05 to 85.05)
        let validLat = min(max(latitude, -85.05), 85.05)
        let latRad = validLat * .pi / 180.0
        
        // Calculate tile coordinates
        let x = Int(floor((longitude + 180.0) / 360.0 * n))
        let y = Int(floor((1.0 - log(tan(latRad) + 1.0 / cos(latRad)) / .pi) / 2.0 * n))
        
        // Get the URL from the API service
        mapURL = APIService.shared.getWeatherMapURL(layer: selectedMapLayer, zoom: zoom, x: x, y: y)
        
        print("Map URL: \(mapURL?.absoluteString ?? "nil") for lat: \(latitude), lon: \(longitude)")
    }
    
    /// Change the weather map layer
    func changeMapLayer(to layer: APIService.WeatherMapLayer) {
        selectedMapLayer = layer
        
        if let location = currentLocation {
            updateWeatherMap(for: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
    }
    
    // MARK: - Location Methods
    
    /// Request location permission from the user
    func requestLocationPermission() {
        locationManager.requestLocationPermission()
    }
    
    /// Refresh all weather data
    func refreshWeatherData() {
        if let location = currentLocation {
            fetchAllWeatherData(for: location.coordinate.latitude, longitude: location.coordinate.longitude)
        } else {
            locationManager.startUpdatingLocation()
        }
    }
    
    /// Search for a location by name
    @MainActor
    func searchLocation(query: String) async {
        await locationManager.searchLocations(query: query)
    }
    
    /// Select a location from search results
    func selectLocation(_ location: GeocodingResult) {
        locationName = location.name
        let clLocation = CLLocation(latitude: location.lat, longitude: location.lon)
        currentLocation = clLocation
        fetchAllWeatherData(for: location.lat, longitude: location.lon)
    }
    
    var searchResults: [GeocodingResult] {
        return locationManager.searchResults
    }
    
    var searchErrorMessage: String? {
        return locationManager.errorMessage
    }
    
    var isSearching: Bool {
        return locationManager.isSearching
    }
}
