import SwiftUI

struct AnalyticsCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let trend: Double?
    let trendIsPositive: Bool?
    
    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        trend: Double? = nil,
        trendIsPositive: Bool? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.trend = trend
        self.trendIsPositive = trendIsPositive
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let trend = trend, let isPositive = trendIsPositive {
                    HStack(spacing: 2) {
                        Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                        Text(String(format: "%.1f%%", abs(trend)))
                    }
                    .font(.footnote)
                    .foregroundColor(isPositive ? .green : .red)
                }
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
} 