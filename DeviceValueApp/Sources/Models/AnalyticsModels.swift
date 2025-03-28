import Foundation
import GRDB

// MARK: - Portfolio Analytics

public struct PortfolioMetrics: Equatable, Sendable {
  public let totalDevices: Int
  public let totalPurchaseValue: Double
  public let totalConsumedValue: Double
  public let remainingValue: Double
  public let averageDeviceAge: Double

  public var consumptionPercentage: Double {
    guard self.totalPurchaseValue > 0 else { return 0 }
    return (self.totalConsumedValue / self.totalPurchaseValue) * 100
  }

  public var remainingValuePercentage: Double {
    guard self.totalPurchaseValue > 0 else { return 0 }
    return (self.remainingValue / self.totalPurchaseValue) * 100
  }

  public init(
    totalDevices: Int,
    totalPurchaseValue: Double,
    totalConsumedValue: Double,
    remainingValue: Double,
    averageDeviceAge: Double
  ) {
    self.totalDevices = totalDevices
    self.totalPurchaseValue = totalPurchaseValue
    self.totalConsumedValue = totalConsumedValue
    self.remainingValue = remainingValue
    self.averageDeviceAge = averageDeviceAge
  }
}

// MARK: - Usage Analytics

public struct UsageMetrics: Equatable, Sendable {
  public struct MonthlyUsage: Equatable, Sendable {
    public let month: Date
    public let consumedValue: Double
    public let currency: String

    public init(month: Date, consumedValue: Double, currency: String) {
      self.month = month
      self.consumedValue = consumedValue
      self.currency = currency
    }
  }

  public let monthlyData: [MonthlyUsage]
  public let averageDailyUsage: Double
  public let projectedAnnualUsage: Double

  public var monthlyUsage: Double {
    self.averageDailyUsage * 30
  }

  public var yearlyUsage: Double {
    self.averageDailyUsage * 365
  }

  public init(monthlyData: [MonthlyUsage], averageDailyUsage: Double, projectedAnnualUsage: Double) {
    self.monthlyData = monthlyData
    self.averageDailyUsage = averageDailyUsage
    self.projectedAnnualUsage = projectedAnnualUsage
  }
}

// MARK: - Device Usage Analytics

public struct DeviceUsageMetrics: Equatable, Identifiable, Sendable {
  public let id: Int64
  public let deviceName: String
  public let purchaseValue: Double
  public let dailyUsageRate: Double
  public let elapsedDays: Int
  public let currencyCode: String

  public var totalPlannedDays: Double {
    self.purchaseValue / self.dailyUsageRate
  }

  public var consumedValue: Double {
    self.dailyUsageRate * Double(self.elapsedDays)
  }

  public var remainingValue: Double {
    max(self.purchaseValue - self.consumedValue, 0)
  }

  public var daysRemaining: Double {
    self.remainingValue / self.dailyUsageRate
  }

  public var consumptionPercentage: Double {
    (self.consumedValue / self.purchaseValue) * 100
  }

  public var expectedConsumptionPercentage: Double {
    min((Double(self.elapsedDays) / self.totalPlannedDays) * 100, 100)
  }

  public var isWithinExpectedUsage: Bool {
    self.consumptionPercentage <= self.expectedConsumptionPercentage
  }

  public init(
    id: Int64,
    deviceName: String,
    purchaseValue: Double,
    dailyUsageRate: Double,
    elapsedDays: Int,
    currencyCode: String
  ) {
    self.id = id
    self.deviceName = deviceName
    self.purchaseValue = purchaseValue
    self.dailyUsageRate = dailyUsageRate
    self.elapsedDays = elapsedDays
    self.currencyCode = currencyCode
  }
}
