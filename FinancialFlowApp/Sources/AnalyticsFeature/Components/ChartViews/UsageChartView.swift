import SwiftUI
import Charts

struct UsageChartView: View {
    let data: [UsageMetrics.MonthlyUsage]
    let currency: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Usage")
                .font(.headline)
            
            Chart(data, id: \.month) { item in
                LineMark(
                    x: .value("Month", item.month, unit: .month),
                    y: .value("Usage", item.consumedValue)
                )
                .foregroundStyle(Color.blue.gradient)
                
                AreaMark(
                    x: .value("Month", item.month, unit: .month),
                    y: .value("Usage", item.consumedValue)
                )
                .foregroundStyle(Color.blue.opacity(0.1))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text("\(currency)\(String(format: "%.0f", doubleValue))")
                        }
                    }
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    UsageChartView(
        data: [
            .init(month: Date(), consumedValue: 100, currency: "$"),
            .init(month: Date().addingTimeInterval(86400 * 30), consumedValue: 150, currency: "$"),
            .init(month: Date().addingTimeInterval(86400 * 60), consumedValue: 120, currency: "$")
        ],
        currency: "$"
    )
} 