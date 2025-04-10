import SwiftUI

struct AirQualityView: View {
    let state: LoadingState<AirQualityResponse>
    let onRetry: () -> Void
    
    var body: some View {
        WeatherCardView(title: "Air Quality") {
            switch state {
            case .idle:
                EmptyView()
                
            case .loading(let progress):
                LoadingView(progress: progress, text: "Loading air quality data...")
                
            case .success(let airQualityResponse):
                if let airQuality = airQualityResponse.list.first {
                    airQualityContent(airQuality)
                } else {
                    Text("No air quality data available")
                        .foregroundColor(.secondary)
                        .padding()
                }
                
            case .failure(let error):
                ErrorView(error: error, retryAction: onRetry)
            }
        }
    }
    
    @ViewBuilder
    private func airQualityContent(_ airQuality: AirQualityData) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Air Quality Index")
                        .font(.headline)
                    
                    Text("Updated \(timeAgo(from: airQuality.date))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                aqiIndicator(level: airQuality.main.aqi, quality: airQuality.qualityLevel)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            Divider()
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                pollutantView(name: "PM2.5", value: airQuality.components.pm2_5, unit: "μg/m³")
                pollutantView(name: "PM10", value: airQuality.components.pm10, unit: "μg/m³")
                pollutantView(name: "NO₂", value: airQuality.components.no2, unit: "μg/m³")
                pollutantView(name: "O₃", value: airQuality.components.o3, unit: "μg/m³")
                pollutantView(name: "SO₂", value: airQuality.components.so2, unit: "μg/m³")
                pollutantView(name: "CO", value: airQuality.components.co, unit: "μg/m³")
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    private func pollutantView(name: String, value: Double, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(alignment: .bottom) {
                Text(String(format: "%.1f", value))
                    .font(.headline)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
    
    private func aqiIndicator(level: Int, quality: String) -> some View {
        HStack(spacing: 4) {
            Text(quality)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(aqiColor(for: level))
                )
            
            Text("\(level)/5")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private func aqiColor(for level: Int) -> Color {
        switch level {
        case 1: return Color.green
        case 2: return Color.blue
        case 3: return Color.yellow
        case 4: return Color.orange
        case 5: return Color.red
        default: return Color.gray
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    VStack {
        // Loading state
        AirQualityView(state: .loading(progress: 0.7), onRetry: {})
            .padding()
        
        // Error state
        AirQualityView(state: .failure(WeatherError.apiError("Air quality data unavailable")), onRetry: {})
            .padding()
    }
    .background(Color(.systemGroupedBackground))
}
