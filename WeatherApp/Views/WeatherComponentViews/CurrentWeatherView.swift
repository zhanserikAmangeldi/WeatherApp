import SwiftUI

struct CurrentWeatherView: View {
    let state: LoadingState<CurrentWeather>
    let onRetry: () -> Void
    
    var body: some View {
        WeatherCardView(title: "Current Weather") {
            switch state {
            case .idle:
                EmptyView()
                
            case .loading(let progress):
                LoadingView(progress: progress, text: "Loading current weather...")
                
            case .success(let weather):
                currentWeatherContent(weather)
                
            case .failure(let error):
                ErrorView(error: error, retryAction: onRetry)
            }
        }
    }
    
    @ViewBuilder
    private func currentWeatherContent(_ weather: CurrentWeather) -> some View {
        VStack(alignment: .center, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    Text(weather.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(formattedDate(weather.date))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let iconURL = weather.iconURL {
                    AsyncImage(url: iconURL) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 70, height: 70)
                        } else {
                            Image(systemName: "cloud.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 70, height: 70)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            Divider()
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(Int(weather.main.temp))°C")
                        .font(.system(size: 40, weight: .bold))
                    
                    Text(weather.weather.first?.description.capitalized ?? "")
                        .font(.title3)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    weatherDetailRow(icon: "thermometer", text: "Feels like: \(Int(weather.main.feels_like))°C")
                    weatherDetailRow(icon: "humidity", text: "Humidity: \(weather.main.humidity)%")
                    weatherDetailRow(icon: "wind", text: "Wind: \(Int(weather.wind.speed)) m/s")
                }
            }
            
            Divider()
            
            HStack(spacing: 15) {
                weatherExtraDetail(icon: "sunrise", title: "Sunrise", value: timeString(from: weather.sys.sunrise))
                
                Divider()
                    .frame(height: 40)
                
                weatherExtraDetail(icon: "sunset", title: "Sunset", value: timeString(from: weather.sys.sunset))
                
                Divider()
                    .frame(height: 40)
                
                weatherExtraDetail(icon: "gauge", title: "Pressure", value: "\(weather.main.pressure) hPa")
            }
            .padding(.top, 4)
        }
        .padding()
    }
    
    private func weatherDetailRow(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.blue)
            Text(text)
                .font(.callout)
        }
    }
    
    private func weatherExtraDetail(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.callout)
                .fontWeight(.medium)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy"
        return formatter.string(from: date)
    }
    
    private func timeString(from timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct WeatherCardView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            content
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    VStack {
        CurrentWeatherView(state: .idle, onRetry: {})
            .padding()
        
        CurrentWeatherView(state: .loading(progress: 0.6), onRetry: {})
            .padding()
        
        CurrentWeatherView(state: .failure(WeatherError.networkError(NSError(domain: "", code: -1009, userInfo: nil))), onRetry: {})
            .padding()
    }
    .background(Color(.systemGroupedBackground))
}
