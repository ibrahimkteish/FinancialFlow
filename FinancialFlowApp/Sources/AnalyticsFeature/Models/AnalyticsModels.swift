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
    let currency: String
    
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

// MARK: - Analytics Time Range
public enum AnalyticsTimeRange: String, CaseIterable, Sendable, Equatable {
    case week = "7 Days"
    case month = "30 Days"
    case quarter = "90 Days"
    case year = "1 Year"
    
    var daysCount: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .year: return 365
        }
    }
} 
