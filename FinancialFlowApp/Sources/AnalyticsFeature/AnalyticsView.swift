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
        portfolioOverview
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

  private var portfolioOverview: some View {
    LazyVGrid(columns: [
      GridItem(.flexible(minimum: 150), spacing: 16, alignment: .center),
      GridItem(.flexible(minimum: 150), spacing: 16, alignment: .center)
    ], spacing: 16) {
      AnalyticsCard(
        title: "Total Purchase Value",
        value: store.formattedTotalPurchaseValue
      )

      AnalyticsCard(
        title: "Remaining Value",
        value: store.formattedRemainingValue
      )

      AnalyticsCard(
        title: "Consumed Value",
        value: store.formattedConsumedValue
      )

      AnalyticsCard(
        title: "Daily Usage",
        value: store.formattedDailyUsage
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
              Text("Daily Rate: \(metric.dailyUsageRate.formatted(.currency(code: metric.currencyCode)))")
                .environment(\.locale, Locale.current)
              Text("Days Left: \(Int(metric.daysRemaining))")
            }
            Spacer()
            VStack(alignment: .trailing) {
              Text("Value Left: \(metric.remainingValue.formatted(.currency(code: metric.currencyCode)))")
                .environment(\.locale, Locale.current)
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
