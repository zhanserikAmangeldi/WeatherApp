import SwiftUI

struct AlertsView: View {
    let state: LoadingState<AlertsResponse>
    let onRetry: () -> Void
    
    @State private var expandedAlertID: UUID?
    
    var body: some View {
        WeatherCardView(title: "Weather Alerts") {
            switch state {
            case .idle:
                EmptyView()
                
            case .loading(let progress):
                LoadingView(progress: progress, text: "Checking for weather alerts...")
                
            case .success(let alertsResponse):
                if let alerts = alertsResponse.alerts, !alerts.isEmpty {
                    alertsContent(alerts)
                } else {
                    noAlertsView()
                }
                
            case .failure(let error):
                ErrorView(error: error, retryAction: onRetry)
            }
        }
    }
    
    @ViewBuilder
    private func alertsContent(_ alerts: [WeatherAlert]) -> some View {
        VStack(spacing: 0) {
            ForEach(alerts) { alert in
                alertView(alert)
                
                if alert.id != alerts.last?.id {
                    Divider()
                        .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func alertView(_ alert: WeatherAlert) -> some View {
        let isExpanded = alert.id == expandedAlertID
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                alertIcon(for: alert.event)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(alert.event)
                        .font(.headline)
                    
                    Text("\(formatDate(alert.startDate)) - \(formatDate(alert.endDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        expandedAlertID = isExpanded ? nil : alert.id
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                Text(alert.description)
                    .font(.subheadline)
                    .lineLimit(nil)
                    .padding(.top, 4)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(alert.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.blue.opacity(0.2))
                                )
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                expandedAlertID = isExpanded ? nil : alert.id
            }
        }
    }
    
    private func noAlertsView() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 36))
                .foregroundColor(.green)
            
            Text("No Weather Alerts")
                .font(.headline)
            
            Text("The weather is clear in this area")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private func alertIcon(for eventType: String) -> some View {
        let iconName: String
        let iconColor: Color
        
        let lowercasedEvent = eventType.lowercased()
        
        if lowercasedEvent.contains("flood") {
            iconName = "drop.fill"
            iconColor = .blue
        } else if lowercasedEvent.contains("storm") || lowercasedEvent.contains("thunder") {
            iconName = "cloud.bolt.fill"
            iconColor = .yellow
        } else if lowercasedEvent.contains("wind") || lowercasedEvent.contains("tornado") {
            iconName = "wind"
            iconColor = .orange
        } else if lowercasedEvent.contains("snow") || lowercasedEvent.contains("blizzard") {
            iconName = "snow"
            iconColor = .cyan
        } else if lowercasedEvent.contains("heat") {
            iconName = "thermometer.sun.fill"
            iconColor = .red
        } else if lowercasedEvent.contains("cold") || lowercasedEvent.contains("freeze") {
            iconName = "thermometer.snowflake"
            iconColor = .blue
        } else {
            iconName = "exclamationmark.triangle.fill"
            iconColor = .orange
        }
        
        return Image(systemName: iconName)
            .font(.title3)
            .foregroundColor(iconColor)
            .frame(width: 30, height: 30)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    VStack {
        AlertsView(state: .loading(progress: 0.8), onRetry: {})
            .padding()
        
        AlertsView(state: .failure(WeatherError.networkError(NSError(domain: "", code: -1009, userInfo: nil))), onRetry: {})
            .padding()
    }
    .background(Color(.systemGroupedBackground))
}
