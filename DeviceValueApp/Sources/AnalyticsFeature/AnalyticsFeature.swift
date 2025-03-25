import ComposableArchitecture
import Foundation
import Models
import SharingGRDB

@Reducer
public struct Analytics: Sendable {
  @ObservableState
  public struct State: Equatable, Sendable {
    @SharedReader(.fetch(PortfolioMetricsRequest()))
    public var portfolioMetrics: PortfolioMetrics?
    @SharedReader(.fetch(UsageMetricsRequest()))
    public var usage: UsageMetrics?
    @SharedReader(.fetch(DeviceUsageMetricsRequest()))
    public var devices: [DeviceUsageMetrics] = []
    @SharedReader(.fetch(DefaultCurrencyRequest()))
    public var defaultCurrency: String = "$"

    public init() {}

    var formattedTotalPurchaseValue: String {
      guard let metrics = portfolioMetrics else { return "N/A" }
      return self.formatCurrency(metrics.totalPurchaseValue)
    }

    var formattedRemainingValue: String {
      guard let metrics = portfolioMetrics else { return "N/A" }
      return self.formatCurrency(metrics.remainingValue)
    }

    var formattedConsumedValue: String {
      guard let metrics = portfolioMetrics else { return "N/A" }
      return self.formatCurrency(metrics.totalConsumedValue)
    }

    var formattedDailyUsage: String {
      guard let metrics = usage else { return "N/A" }
      return self.formatCurrency(metrics.averageDailyUsage)
    }

    private func formatCurrency(_ value: Double) -> String {
      let formatter = NumberFormatter()
      formatter.numberStyle = .currency
      formatter.maximumFractionDigits = 2
      formatter.currencySymbol = self.defaultCurrency
      return formatter.string(from: NSNumber(value: value)) ?? "N/A"
    }
  }

  public enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
  }

  public struct DeviceUsageMetricsRequest: FetchKeyRequest {
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
              c.code as currency_code
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
          currencyCode: row["currency_code"] as? String ?? "USD"
        )
      }
    }
  }

  public struct UsageMetricsRequest: FetchKeyRequest {
    public init() {}

    public func fetch(_ db: Database) throws -> UsageMetrics? {
      // First get the default currency
      let defaultCurrencyRow = try Row.fetchOne(db, sql: "SELECT defaultCurrencyId FROM app_settings LIMIT 1")
      let defaultCurrencyId = defaultCurrencyRow?["defaultCurrencyId"] as? Int64 ?? 1 // Fallback to 1 (USD)

      // Calculate daily usage using the same approach as HomeFeature
      let sql = """
      WITH total_in_usd AS (
          -- First convert everything to USD (multiply by the inverse of usdRate for non-USD currencies)
          SELECT SUM(
              CASE 
                  WHEN c.code = 'USD' THEN d.usageRate 
                  ELSE d.usageRate * (1.0 / c.usdRate)
              END / urp.daysMultiplier
          ) AS usd_total,
          strftime('%Y-%m', 'now') as current_month
          FROM devices d
          JOIN currencies c ON d.currencyId = c.id
          JOIN usage_rate_periods urp ON d.usageRatePeriodId = urp.id
      )
      SELECT 
          tu.current_month as month,
          c.code AS currency_code,
          CASE 
              -- For USD, return as is
              WHEN c.code = 'USD' THEN tu.usd_total
              -- For other currencies, convert from USD to target currency
              ELSE tu.usd_total * c.usdRate
          END AS daily_usage
      FROM total_in_usd tu
      JOIN currencies c ON c.id = ?
      """

      let row = try Row.fetchOne(db, sql: sql, arguments: [defaultCurrencyId])
      let dailyUsage = row?["daily_usage"] as? Double ?? 0
      let currencyCode = row?["currency_code"] as? String ?? "USD"
      let currencySymbol = try Row.fetchOne(
        db,
        sql: "SELECT symbol FROM currencies WHERE code = ?",
        arguments: [currencyCode]
      )?["symbol"] as? String ?? "$"

      // Create a simple monthly usage with the current month
      let monthlyData = [
        UsageMetrics.MonthlyUsage(
          month: Date(),
          consumedValue: dailyUsage * 30, // Monthly equivalent
          currency: currencySymbol
        )
      ]

      return UsageMetrics(
        monthlyData: monthlyData,
        averageDailyUsage: dailyUsage,
        projectedAnnualUsage: dailyUsage * 365
      )
    }
  }

  public struct PortfolioMetricsRequest: FetchKeyRequest {

    public func fetch(_ db: Database) throws -> PortfolioMetrics? {
      // First get the default currency
      let defaultCurrencyRow = try Row.fetchOne(db, sql: "SELECT defaultCurrencyId FROM app_settings LIMIT 1")
      let defaultCurrencyId = defaultCurrencyRow?["defaultCurrencyId"] as? Int64 ?? 1 // Fallback to 1 (USD)

      let sql = """
      WITH values_in_default AS (
          -- Convert all values to default currency
          SELECT 
              COUNT(*) as totalDevices,
              SUM(
                  CASE 
                      -- For same currency, use as is
                      WHEN d.currencyId = ? THEN d.purchasePrice
                      -- For USD to other, multiply by exchange rate
                      WHEN target.code = 'USD' THEN d.purchasePrice * (1.0 / source.usdRate)
                      -- For other to USD, multiply by USD rate
                      WHEN source.code = 'USD' THEN d.purchasePrice * target.usdRate
                      -- For other currencies, convert through USD
                      ELSE d.purchasePrice * (1.0 / source.usdRate) * target.usdRate
                  END
              ) as totalPurchaseValue,
              AVG(julianday('now') - julianday(d.purchaseDate)) as averageAge,
              SUM(
                  CASE 
                      -- For same currency, use as is
                      WHEN d.currencyId = ? THEN
                          CASE 
                              WHEN d.usageRatePeriodId = 1 THEN d.usageRate * (julianday('now') - julianday(d.purchaseDate))
                              WHEN d.usageRatePeriodId = 2 THEN d.usageRate * ((julianday('now') - julianday(d.purchaseDate))/7)
                              WHEN d.usageRatePeriodId = 3 THEN d.usageRate * ((julianday('now') - julianday(d.purchaseDate))/30)
                              ELSE d.usageRate * ((julianday('now') - julianday(d.purchaseDate))/365)
                          END
                      -- For different currencies, convert the usage rate first
                      ELSE
                          CASE 
                              WHEN d.usageRatePeriodId = 1 THEN 
                                  (CASE 
                                      WHEN target.code = 'USD' THEN d.usageRate * (1.0 / source.usdRate)
                                      WHEN source.code = 'USD' THEN d.usageRate * target.usdRate
                                      ELSE d.usageRate * (1.0 / source.usdRate) * target.usdRate
                                  END) * (julianday('now') - julianday(d.purchaseDate))
                              WHEN d.usageRatePeriodId = 2 THEN 
                                  (CASE 
                                      WHEN target.code = 'USD' THEN d.usageRate * (1.0 / source.usdRate)
                                      WHEN source.code = 'USD' THEN d.usageRate * target.usdRate
                                      ELSE d.usageRate * (1.0 / source.usdRate) * target.usdRate
                                  END) * ((julianday('now') - julianday(d.purchaseDate))/7)
                              WHEN d.usageRatePeriodId = 3 THEN 
                                  (CASE 
                                      WHEN target.code = 'USD' THEN d.usageRate * (1.0 / source.usdRate)
                                      WHEN source.code = 'USD' THEN d.usageRate * target.usdRate
                                      ELSE d.usageRate * (1.0 / source.usdRate) * target.usdRate
                                  END) * ((julianday('now') - julianday(d.purchaseDate))/30)
                              ELSE 
                                  (CASE 
                                      WHEN target.code = 'USD' THEN d.usageRate * (1.0 / source.usdRate)
                                      WHEN source.code = 'USD' THEN d.usageRate * target.usdRate
                                      ELSE d.usageRate * (1.0 / source.usdRate) * target.usdRate
                                  END) * ((julianday('now') - julianday(d.purchaseDate))/365)
                          END
                  END
              ) as totalConsumedValue
          FROM devices d
          JOIN currencies source ON d.currencyId = source.id
          JOIN currencies target ON target.id = ?
      )
      SELECT * FROM values_in_default
      """

      let row = try Row.fetchOne(db, sql: sql, arguments: [defaultCurrencyId, defaultCurrencyId, defaultCurrencyId])

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

  public struct DefaultCurrencyRequest: FetchKeyRequest {
    public typealias State = String

    public init() {}

    public func fetch(_ db: Database) throws -> String {
      let sql = """
      SELECT 
          c.symbol as currency_symbol
      FROM app_settings s
      JOIN currencies c ON s.defaultCurrencyId = c.id
      LIMIT 1
      """

      if let row = try Row.fetchOne(db, sql: sql),
         let symbol = row["currency_symbol"] as? String {
        return symbol
      }

      // Fallback to USD if no default currency is set
      return "$"
    }
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { _, action in
      switch action {
        case .binding:
          return .none
      }
    }
  }
}
