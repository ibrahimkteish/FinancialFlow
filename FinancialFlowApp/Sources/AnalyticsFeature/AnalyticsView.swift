import SwiftUI
import ComposableArchitecture

public struct AnalyticsView: View {
  @Bindable var store: StoreOf<Analytics>

  public init(store: StoreOf<Analytics>) {
    self.store = store
  }

  public var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        timeRangePicker
        portfolioOverview
        if let usageMetrics = store.usage {
          UsageChartView(
            data: usageMetrics.monthlyData,
            currency: "$"
          )
          .padding(.horizontal)
        }
        deviceUsageList
      }
      .padding(.vertical)
    }
    .navigationTitle("Usage Analytics")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          store.send(.refresh)
        } label: {
          Image(systemName: "arrow.clockwise")
        }
      }
    }
  }

  private var timeRangePicker: some View {
    Picker("Time Range", selection: self.$store.selectedTimeRange) {
      ForEach(AnalyticsTimeRange.allCases, id: \.self) { range in
        Text(range.rawValue).tag(range)
      }
    }
    .pickerStyle(.segmented)
    .padding(.horizontal)
  }

  private var portfolioOverview: some View {
    LazyVGrid(columns: [
      GridItem(.flexible()),
      GridItem(.flexible())
    ], spacing: 16) {
      AnalyticsCard(
        title: "Total Purchase Value",
        value: store.formattedTotalPurchaseValue
      )

      AnalyticsCard(
        title: "Remaining Value",
        value: store.formattedRemainingValue,
        trend: store.portfolioMetrics?.remainingValuePercentage,
        trendIsPositive: store.portfolioMetrics?.remainingValuePercentage ?? 0 > 50
      )

      AnalyticsCard(
        title: "Consumed Value",
        value: store.formattedConsumedValue
      )

      AnalyticsCard(
        title: "Daily Usage",
        value: store.formattedDailyUsage,
        subtitle: "Average across all devices"
      )
    }
    .padding(.horizontal)
  }

  private var deviceUsageList: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Device Usage")
        .font(.headline)
        .padding(.horizontal)

      ForEach(store.devices) { metric in
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text(metric.deviceName)
              .font(.subheadline)
              .fontWeight(.medium)

            Spacer()

            Text("\(Int(metric.consumptionPercentage))% used")
              .foregroundColor(metric.isWithinExpectedUsage ? .red : .green)
          }

          HStack {
            VStack(alignment: .leading) {
              Text("Daily Rate: \(metric.currency)\(String(format: "%.2f", metric.dailyUsageRate))")
              Text("Days Left: \(Int(metric.daysRemaining))")
            }
            Spacer()
            VStack(alignment: .trailing) {
              Text("Value Left: \(metric.currency)\(String(format: "%.2f", metric.remainingValue))")
              Text("Expected: \(Int(metric.expectedConsumptionPercentage))%")
            }
          }
          .font(.caption)
          .foregroundColor(.secondary)

          // Usage slider (hidden thumb)
          HiddenThumbSlider(value: Double(metric.consumptionPercentage), range: 0...100, accentColor: metric.isWithinExpectedUsage ? UIColor.red : UIColor.green)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
      }
    }
  }
}

#Preview {
  NavigationView {
    AnalyticsView(
      store: Store(
        initialState: Analytics.State()
      ) {
        Analytics()
      }
    )
  }
}
