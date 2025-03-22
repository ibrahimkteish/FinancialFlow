import Foundation
import GRDB
import Models
import ComposableArchitecture
import SharingGRDB

public actor AnalyticsService: Sendable {
    @Dependency(\.defaultDatabase) private var database
    
    public init() {}
    
    // MARK: - Portfolio Metrics
    public func fetchPortfolioMetrics() async throws -> PortfolioMetrics {
        try await database.read { db in
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
    
    // MARK: - Usage Metrics
    public func fetchDepreciationMetrics(timeRange: AnalyticsTimeRange) async throws -> UsageMetrics {
        try await database.read { db in
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
    
    // MARK: - Device Usage Metrics
    public func fetchDevicePerformanceMetrics() async throws -> [DeviceUsageMetrics] {
        try await database.read { db in
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
} 
