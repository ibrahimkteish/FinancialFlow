import ComposableArchitecture
import Foundation
import Models
import SharingGRDB

@Reducer
public struct Analytics: Sendable {
  @ObservableState
  public struct State: Equatable, Sendable {
    @SharedReader(.fetch(PMetrics()))
    public var portfolioMetrics: PortfolioMetrics?
    @SharedReader(.fetch(UMetrics(timeRange: .month)))
    public var usage: UsageMetrics?
    @SharedReader(.fetch(DUMetrics()))
    public var devices: [DeviceUsageMetrics] = []
    public var selectedTimeRange: AnalyticsTimeRange = .month

    public init() {}

    var formattedTotalPurchaseValue: String {
      guard let metrics = portfolioMetrics else { return "N/A" }
      return formatCurrency(metrics.totalPurchaseValue)
    }

    var formattedRemainingValue: String {
      guard let metrics = portfolioMetrics else { return "N/A" }
      return formatCurrency(metrics.remainingValue)
    }

    var formattedConsumedValue: String {
      guard let metrics = portfolioMetrics else { return "N/A" }
      return formatCurrency(metrics.totalConsumedValue)
    }

    var formattedDailyUsage: String {
      guard let metrics = usage else { return "N/A" }
      return formatCurrency(metrics.averageDailyUsage)
    }

    private func formatCurrency(_ value: Double) -> String {
      let formatter = NumberFormatter()
      formatter.numberStyle = .currency
      formatter.maximumFractionDigits = 2
      return formatter.string(from: NSNumber(value: value)) ?? "N/A"
    }
  }

  public enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case refresh
  }

  public struct DUMetrics: FetchKeyRequest {
    public init() {}

    public func fetch(_ db: Database) throws -> [DeviceUsageMetrics] {
      let sql = """
                SELECT 
                    d.id,
                    d.name as deviceName,
                    d.purchasePrice as purchaseValue,
                    CASE 
                        WHEN d.usageRatePeriodId = 1 THEN d.usageRate
                        WHEN d.usageRatePeriodId = 2 THEN d.usageRate / 7
                        WHEN d.usageRatePeriodId = 3 THEN d.usageRate / 30
                        ELSE d.usageRate / 365
                    END as daily_usage_rate,
                    julianday('now') - julianday(d.purchaseDate) as elapsed_days,
                    c.symbol as currency
                FROM devices d
                JOIN currencies c ON d.currencyId = c.id
            """

      return try Row.fetchAll(db, sql: sql).map { row in
        let dailyUsageRate = row["daily_usage_rate"] as? Double ?? 0
        let elapsedDays = Int(row["elapsed_days"] as? Double ?? 0)

        return DeviceUsageMetrics(
          id: row["id"] as? Int64 ?? 0,
          deviceName: row["deviceName"] as? String ?? "",
          purchaseValue: row["purchaseValue"] as? Double ?? 0,
          dailyUsageRate: dailyUsageRate,
          elapsedDays: elapsedDays,
          currency: row["currency"] as? String ?? "$"
        )
      }
    }
  }

  public struct UMetrics: FetchKeyRequest {
    let timeRange: AnalyticsTimeRange

    public func fetch(_ db: Database) throws -> UsageMetrics? {
      let sql = """
                WITH RECURSIVE dates(date) AS (
                    SELECT date('now', '-\(timeRange.daysCount) days')
                    UNION ALL
                    SELECT date(date, '+1 month')
                    FROM dates
                    WHERE date < date('now')
                )
                SELECT 
                    dates.date as month,
                    COALESCE(SUM(
                        CASE 
                            WHEN d.usageRatePeriodId = 1 THEN d.usageRate
                            WHEN d.usageRatePeriodId = 2 THEN d.usageRate / 7
                            WHEN d.usageRatePeriodId = 3 THEN d.usageRate / 30
                            ELSE d.usageRate / 365
                        END
                    ), 0) as daily_usage,
                    c.symbol as currency
                FROM dates
                LEFT JOIN devices d ON strftime('%Y-%m', d.purchaseDate) <= strftime('%Y-%m', dates.date)
                LEFT JOIN currencies c ON d.currencyId = c.id
                GROUP BY strftime('%Y-%m', dates.date), c.symbol
                ORDER BY dates.date
            """

      let rows = try Row.fetchAll(db, sql: sql)

      let monthlyData = rows.map { row in
        UsageMetrics.MonthlyUsage(
          month: row["month"] as? Date ?? Date(),
          consumedValue: (row["daily_usage"] as? Double ?? 0) * 30, // Convert daily to monthly
          currency: row["currency"] as? String ?? "$"
        )
      }

      let averageDailyUsage = monthlyData.map { $0.consumedValue }.reduce(0, +) / Double(monthlyData.count) / 30
      let projectedAnnualUsage = averageDailyUsage * 365

      return UsageMetrics(
        monthlyData: monthlyData,
        averageDailyUsage: averageDailyUsage,
        projectedAnnualUsage: projectedAnnualUsage
      )
    }
  }

  public struct PMetrics: FetchKeyRequest {

    public func fetch(_ db: Database) throws -> PortfolioMetrics? {
      let sql = """
                SELECT 
                    COUNT(*) as totalDevices,
                    SUM(purchasePrice) as totalPurchaseValue,
                    AVG(julianday('now') - julianday(purchaseDate)) as averageAge,
                    SUM(
                        CASE 
                            WHEN d.usageRatePeriodId = 1 THEN d.usageRate * (julianday('now') - julianday(d.purchaseDate))
                            WHEN d.usageRatePeriodId = 2 THEN d.usageRate * ((julianday('now') - julianday(d.purchaseDate))/7)
                            WHEN d.usageRatePeriodId = 3 THEN d.usageRate * ((julianday('now') - julianday(d.purchaseDate))/30)
                            ELSE d.usageRate * ((julianday('now') - julianday(d.purchaseDate))/365)
                        END
                    ) as totalConsumedValue
                FROM devices d
            """

      let row = try Row.fetchOne(db, sql: sql)

      let totalDevices = row?["totalDevices"] as? Int ?? 0
      let totalPurchaseValue = row?["totalPurchaseValue"] as? Double ?? 0
      let averageAge = row?["averageAge"] as? Double ?? 0
      let totalConsumedValue = row?["totalConsumedValue"] as? Double ?? 0
      let remainingValue = max(0, totalPurchaseValue - totalConsumedValue)

      return PortfolioMetrics(
        totalDevices: totalDevices,
        totalPurchaseValue: totalPurchaseValue,
        totalConsumedValue: totalConsumedValue,
        remainingValue: remainingValue,
        averageDeviceAge: averageAge
      )
    }
  }

  @Dependency(\.analyticsService) var analyticsService

  public init() {}

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        case .binding(\.selectedTimeRange):
          return .run { [state] _ in
            try await state.$usage.load(.fetch(UMetrics(timeRange: state.selectedTimeRange)))
          }

        case .binding:
          return .none

        case .refresh:
          return .none
      }
    }
  }
}

// MARK: - Dependencies
extension DependencyValues {
    var analyticsService: AnalyticsService {
        get { self[AnalyticsServiceKey.self] }
        set { self[AnalyticsServiceKey.self] = newValue }
    }
}

private enum AnalyticsServiceKey: DependencyKey {
    static let liveValue = AnalyticsService()
} 
