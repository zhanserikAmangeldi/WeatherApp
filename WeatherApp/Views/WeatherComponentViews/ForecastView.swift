import SwiftUI

struct ForecastView: View {
    let state: LoadingState<ForecastResponse>
    let onRetry: () -> Void
    
    var body: some View {
        WeatherCardView(title: "5-Day Forecast") {
            switch state {
            case .idle:
                EmptyView()
                
            case .loading(let progress):
                LoadingView(progress: progress, text: "Loading forecast data...")
                
            case .success(let forecastResponse):
                forecastContent(forecastResponse)
                
            case .failure(let error):
                ErrorView(error: error, retryAction: onRetry)
            }
        }
    }
    
    @ViewBuilder
    private func forecastContent(_ forecastResponse: ForecastResponse) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            let dailyForecasts = processForecastData(forecastResponse.list)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(dailyForecasts) { dailyForecast in
                        dailyForecastView(dailyForecast)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
    }
    
    private func dailyForecastView(_ forecast: DailyForecast) -> some View {
        VStack(spacing: 8) {
            Text(dayOfWeek(from: forecast.date))
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(shortDate(from: forecast.date))
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let iconURL = forecast.iconURL {
                AsyncImage(url: iconURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                    } else {
                        Image(systemName: "cloud.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            VStack(spacing: 4) {
                Text("\(Int(forecast.maxTemp))°")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("\(Int(forecast.minTemp))°")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 4) {
                Image(systemName: "drop.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("\(Int(forecast.precipitationChance * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 80)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground).opacity(0.4))
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
    }
    
    private func processForecastData(_ forecastItems: [ForecastItem]) -> [DailyForecast] {
        let calendar = Calendar.current
        
        let groupedByDay = Dictionary(grouping: forecastItems) { item in
            calendar.startOfDay(for: item.date)
        }
        
        return groupedByDay.map { day, items in
            let maxTemp = items.map { $0.main.temp_max }.max() ?? 0
            let minTemp = items.map { $0.main.temp_min }.min() ?? 0
            
            let precipitationChance = items.map { $0.pop }.reduce(0, +) / Double(items.count)
            
            let middayItem = items.first { item in
                let hour = calendar.component(.hour, from: item.date)
                return (12...15).contains(hour)
            } ?? items.first!
            
            return DailyForecast(
                id: UUID(),
                date: day,
                maxTemp: maxTemp,
                minTemp: minTemp,
                precipitationChance: precipitationChance,
                iconURL: middayItem.iconURL,
                description: middayItem.weather.first?.description ?? ""
            )
        }
        .sorted { $0.date < $1.date }
    }
    
    private func dayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func shortDate(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}

struct DailyForecast: Identifiable {
    let id: UUID
    let date: Date
    let maxTemp: Double
    let minTemp: Double
    let precipitationChance: Double
    let iconURL: URL?
    let description: String
}

#Preview {
    VStack {
        ForecastView(state: .loading(progress: 0.5), onRetry: {})
            .padding()
        
        ForecastView(state: .failure(WeatherError.apiError("Forecast data unavailable")), onRetry: {})
            .padding()
    }
    .background(Color(.systemGroupedBackground))
}
