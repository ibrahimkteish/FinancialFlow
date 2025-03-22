import Foundation
import GRDB

// MARK: - Portfolio Analytics
public struct PortfolioMetrics: Equatable, Sendable {
    let totalDevices: Int
    let totalPurchaseValue: Double
    let totalConsumedValue: Double
    let remainingValue: Double
    let averageDeviceAge: Double
    
    var consumptionPercentage: Double {
        guard totalPurchaseValue > 0 else { return 0 }
        return (totalConsumedValue / totalPurchaseValue) * 100
    }
    
    var remainingValuePercentage: Double {
        guard totalPurchaseValue > 0 else { return 0 }
        return (remainingValue / totalPurchaseValue) * 100
    }
}

// MARK: - Usage Analytics
public struct UsageMetrics: Equatable, Sendable {
    struct MonthlyUsage: Equatable {
        let month: Date
        let consumedValue: Double
        let currency: String
    }
    
    let monthlyData: [MonthlyUsage]
    let averageDailyUsage: Double
    let projectedAnnualUsage: Double
    
    var monthlyUsage: Double {
        averageDailyUsage * 30
    }
    
    var yearlyUsage: Double {
        averageDailyUsage * 365
    }
}

// MARK: - Device Usage Analytics
public struct DeviceUsageMetrics: Equatable, Identifiable, Sendable {
    public let id: Int64
    let deviceName: String
    let purchaseValue: Double
    let dailyUsageRate: Double
    let elapsedDays: Int
    let currencyCode: String

    var totalPlannedDays: Double {
        purchaseValue / dailyUsageRate
    }
    
    var consumedValue: Double {
        dailyUsageRate * Double(elapsedDays)
    }
    
    var remainingValue: Double {
        max(purchaseValue - consumedValue, 0)
    }
    
    var daysRemaining: Double {
        remainingValue / dailyUsageRate
    }
    
    var consumptionPercentage: Double {
        (consumedValue / purchaseValue) * 100
    }
    
    var expectedConsumptionPercentage: Double {
        min((Double(elapsedDays) / totalPlannedDays) * 100, 100)
    }
    
    var isWithinExpectedUsage: Bool {
        consumptionPercentage <= expectedConsumptionPercentage
    }
} 
