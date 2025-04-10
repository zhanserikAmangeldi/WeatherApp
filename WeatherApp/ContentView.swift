import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var viewModel = WeatherViewModel()
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var showLocationResults = false
    
    @State private var refreshTrigger = UUID()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    simpleSearchBar
                    
                    if showLocationResults {
                        searchResultsList
                    } else {
                        weatherContentView
                    }
                }
            }
            .navigationTitle(viewModel.locationName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            viewModel.refreshWeatherData()
                            refreshTrigger = UUID()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                viewModel.requestLocationPermission()
            }
        }
    }
    
    private var simpleSearchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search for a city", text: $searchText)
                    .disableAutocorrection(true)
                    .submitLabel(.search)
                    .onSubmit {
                        searchLocation()
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            if isSearching || showLocationResults {
                Button("Cancel") {
                    searchText = ""
                    showLocationResults = false
                    isSearching = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .transition(.move(edge: .trailing))
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var searchResultsList: some View {
        VStack {
            if viewModel.isSearching {
                ProgressView()
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else if viewModel.searchResults.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.searchErrorMessage ?? "No locations found")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(viewModel.searchResults) { result in
                            locationResultRow(result)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .transition(.opacity)
    }
    
    private func locationResultRow(_ result: GeocodingResult) -> some View {
        Button(action: {
            selectLocation(result)
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.name)
                        .font(.headline)
                    
                    Text(result.country + (result.state != nil ? ", \(result.state!)" : ""))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var weatherContentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                CurrentWeatherView(
                    state: viewModel.currentWeatherState,
                    onRetry: { viewModel.refreshWeatherData() }
                )
                .id("current-\(refreshTrigger)")
                .transition(.opacity)
                
                ForecastView(
                    state: viewModel.forecastState,
                    onRetry: { viewModel.refreshWeatherData() }
                )
                .id("forecast-\(refreshTrigger)")
                .transition(.opacity)
                
                WeatherMapView(
                    mapURL: viewModel.mapURL,
                    selectedLayer: viewModel.selectedMapLayer,
                    onLayerChange: { layer in
                        viewModel.changeMapLayer(to: layer)
                    }
                )
                .id("map-\(refreshTrigger)")
                .transition(.opacity)
                
                AirQualityView(
                    state: viewModel.airQualityState,
                    onRetry: { viewModel.refreshWeatherData() }
                )
                .id("airquality-\(refreshTrigger)")
                .transition(.opacity)
                
                AlertsView(
                    state: viewModel.alertsState,
                    onRetry: { viewModel.refreshWeatherData() }
                )
                .id("alerts-\(refreshTrigger)")
                .transition(.opacity)
            }
            .padding()
            .animation(.default, value: refreshTrigger)
        }
        .refreshable {
            viewModel.refreshWeatherData()
            refreshTrigger = UUID()
        }
    }
    
    private func searchLocation() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        showLocationResults = true
        
        Task {
            await viewModel.searchLocation(query: searchText)
            isSearching = false
        }
    }
    
    private func selectLocation(_ location: GeocodingResult) {
        withAnimation {
            viewModel.selectLocation(location)
            searchText = ""
            showLocationResults = false
            isSearching = false
        }
    }
}

#Preview {
    ContentView()
}
