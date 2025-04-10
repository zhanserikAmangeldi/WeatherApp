import SwiftUI

struct WeatherMapView: View {
    let mapURL: URL?
    let selectedLayer: APIService.WeatherMapLayer
    let onLayerChange: (APIService.WeatherMapLayer) -> Void
    
    @State private var isLoading = true
    @State private var isShowingLayerPicker = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        WeatherCardView(title: "Weather Map") {
            VStack(spacing: 0) {
                layerControl
                
                ZStack {
                    if let url = mapURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .frame(maxWidth: .infinity, maxHeight: 180)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                                
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                                
                            case .failure:
                                VStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.largeTitle)
                                        .foregroundColor(.orange)
                                    
                                    Text("Map unavailable")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Try a different map layer")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: 180)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .padding(.horizontal)
                                
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        noMapView
                    }
                }
                .frame(height: 200)
            }
        }
    }
    
    private var layerControl: some View {
        HStack {
            Text(layerName(selectedLayer))
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: {
                isShowingLayerPicker.toggle()
            }) {
                HStack {
                    Text("Change")
                        .font(.subheadline)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .confirmationDialog("Select Map Layer", isPresented: $isShowingLayerPicker, titleVisibility: .visible) {
            Button("Precipitation") { onLayerChange(.precipitation) }
            Button("Temperature") { onLayerChange(.temperature) }
            Button("Pressure") { onLayerChange(.pressure) }
            Button("Wind") { onLayerChange(.wind) }
            Button("Clouds") { onLayerChange(.clouds) }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private var noMapView: some View {
        VStack(spacing: 8) {
            Image(systemName: "map")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("Map unavailable")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("No location data available")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: 180)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private func layerName(_ layer: APIService.WeatherMapLayer) -> String {
        switch layer {
        case .precipitation:
            return "Precipitation"
        case .temperature:
            return "Temperature"
        case .pressure:
            return "Pressure"
        case .wind:
            return "Wind Speed"
        case .clouds:
            return "Cloud Cover"
        }
    }
}

#Preview {
    WeatherMapView(
        mapURL: URL(string: "https://tile.openweathermap.org/map/precipitation_new/5/15/15.png?appid=YOUR_API_KEY"),
        selectedLayer: .precipitation,
        onLayerChange: { _ in }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
