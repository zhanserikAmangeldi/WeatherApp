# Weather App

A SwiftUI weather application that demonstrates Swift's modern concurrency features by fetching multiple weather data points concurrently from the OpenWeatherMap API.

## Features

- **Current Weather**: Displays current conditions including temperature, feels like, humidity, wind speed, sunrise/sunset times, and pressure.
- **5-Day Forecast**: Shows a 5-day weather forecast with daily high/low temperatures and precipitation chances.
- **Weather Maps**: Interactive weather maps with different layers (precipitation, temperature, wind, clouds, pressure).
- **Air Quality**: Shows air quality index and detailed pollutant information.
- **Weather Alerts**: Displays any active weather alerts or warnings for the selected location.
- **Location Search**: Search for any location worldwide to view its weather data.
- **Concurrent Data Loading**: All weather components load simultaneously using Swift's modern concurrency features.
- **Immediate UI Updates**: Each component updates independently as its data becomes available.
- **Loading States**: Progress indicators show loading status for each component.
- **Error Handling**: Proper error display and retry functionality for failed requests.
- **Data Caching**: Improved performance through caching of recently fetched data.
- **Cancellation**: Support for cancelling ongoing network requests when the user changes location.

## Architecture

This app implements the MVVM (Model-View-ViewModel) architecture pattern:

- **Models**: Data structures that represent weather information
- **Views**: SwiftUI views that display the weather data
- **ViewModels**: Manages data fetching, processing, and UI state

## Swift Concurrency Implementation

The app demonstrates several modern Swift concurrency features:

- **async/await**: Used for all network requests and asynchronous operations
- **Task**: Manages asynchronous work and provides cancellation support
- **TaskGroup**: Coordinates multiple concurrent data fetching operations
- **@MainActor**: Ensures UI updates happen on the main thread
- **Structured Concurrency**: Properly manages the lifecycle of asynchronous operations

## Setup Instructions

### API Key Setup

1. Sign up for a free API key at [OpenWeatherMap](https://openweathermap.org/api)
2. Open the project in Xcode
3. Locate the `APIService.swift` file
4. Replace the empty `apiKey` string with your API key:
   ```swift
   private let apiKey = "YOUR_API_KEY_HERE" // Add your API key here
   ```

### Build and Run
1. Open `WeatherConcurrency.xcodeproj` in Xcode
2. Select your target device or simulator
3. Build and run the app (⌘+R)

## Project Structure

```
WeatherConcurrency/
├── Models/
│   ├── WeatherData.swift        # Weather data models
│   ├── LoadingState.swift       # Enum for component loading states
│   └── WeatherError.swift       # Custom error types
├── ViewModels/
│   └── WeatherViewModel.swift   # Main ViewModel with concurrency implementation
├── Views/
│   ├── ContentView.swift        # Main container view
│   ├── WeatherComponentViews/   # Individual weather component views
│   └── Common/                  # Reusable UI components
└── Services/
    ├── APIService.swift         # Network service for API requests
    ├── LocationManager.swift    # Location services handler
    └── CacheService.swift       # Data caching implementation
```

## Concurrency Implementation Details

### Concurrent Data Fetching
The app uses `TaskGroup` to fetch multiple weather data types simultaneously:

```swift
private func fetchDataConcurrently(lat: Double, lon: Double) async {
    await withTaskGroup(of: Void.self) { group in
        // Add concurrent tasks for each data type
        group.addTask { await self.fetchCurrentWeather(lat: lat, lon: lon) }
        group.addTask { await self.fetchForecast(lat: lat, lon: lon) }
        group.addTask { await self.fetchAirQuality(lat: lat, lon: lon) }
        group.addTask { await self.fetchAlerts(lat: lat, lon: lon) }
        
        // Wait for all tasks to complete
        for await _ in group {}
    }
}
```

### Task Cancellation
When the user changes location or refreshes the data, any ongoing tasks are cancelled:

```swift
func cancelCurrentDataTask() {
    currentDataTask?.cancel()
    currentDataTask = nil
}
```

### Loading States
Each component has its own loading state that updates independently:

```swift
enum LoadingState<T> {
    case idle
    case loading(progress: Double? = nil)
    case success(T)
    case failure(Error)
}
```

## Known Limitations

- The app requires an internet connection to function properly
- The free OpenWeatherMap API has rate limits that may affect functionality with frequent usage
- Weather map functionality may be limited with the free API tier

## Third-Party Libraries

This project does not use any third-party libraries to demonstrate pure Swift and SwiftUI implementation with native concurrency features.

## Video demonstration

https://youtube.com/shorts/4Q5iw5oTbsQ?feature=share
