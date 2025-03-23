import SwiftUI
import ComposableArchitecture
import Generated

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
    .navigationTitle(Strings.usageAnalytics)
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
        title: Strings.totalPurchaseValue,
        value: store.formattedTotalPurchaseValue
      )

      AnalyticsCard(
        title: Strings.remainingValue,
        value: store.formattedRemainingValue
      )

      AnalyticsCard(
        title: Strings.consumedValue,
        value: store.formattedConsumedValue
      )

      AnalyticsCard(
        title: Strings.dailyUsage,
        value: store.formattedDailyUsage
      )
    }
    .padding(.horizontal)
  }

  private var deviceUsageList: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(Strings.deviceUsage)
        .font(.headline)
        .padding(.horizontal)

      ForEach(store.devices) { metric in
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text(metric.deviceName)
              .font(.subheadline)
              .fontWeight(.medium)

            Spacer()

            Text(Strings.percentUsed(Int(metric.consumptionPercentage)))
              .foregroundColor(metric.isWithinExpectedUsage ? .red : .green)
          }

          HStack {
            VStack(alignment: .leading) {
              Text(Strings.dailyRate(metric.dailyUsageRate.formatted(.currency(code: metric.currencyCode))))
                .environment(\.locale, Locale.current)
              Text(Strings.daysLeft(Int(metric.daysRemaining)))
            }
            Spacer()
            VStack(alignment: .trailing) {
              Text(Strings.valueLeft(metric.remainingValue.formatted(.currency(code: metric.currencyCode))))
                .environment(\.locale, Locale.current)
              Text(Strings.expected(Int(metric.expectedConsumptionPercentage)))
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
