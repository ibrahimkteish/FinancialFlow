//
//  Models.swift
//  FinancialFlowApp
//
//  Created by Ibrahim Koteish on 15/2/25.
//

import Foundation
import GRDB
import IssueReporting
import Sharing
import ConcurrencyExtras
import Utils

public struct UsageRatePeriod: Equatable, Codable, FetchableRecord, PersistableRecord, Sendable {
    public static let databaseTableName = "usage_rate_periods"

    public var id: Int64?
    public var name: String  // "day", "week", "month", "year"
    public var daysMultiplier: Int  // 1 for day, 7 for week, etc.

    public init(id: Int64? = nil, name: String, daysMultiplier: Int) {
        self.id = id
        self.name = name
        self.daysMultiplier = daysMultiplier
    }
}

#if DEBUG
extension UsageRatePeriod {
    public static let day = UsageRatePeriod(id: 1, name: "day", daysMultiplier: 1)
    public static let week = UsageRatePeriod(id: 2, name: "week", daysMultiplier: 7)
    public static let month = UsageRatePeriod(id: 3, name: "month", daysMultiplier: 30)
    public static let year = UsageRatePeriod(id: 4, name: "year", daysMultiplier: 365)
}
#endif

public struct Device: Codable, Equatable, Identifiable, Sendable, FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "devices"

    public var id: Int64?
    public var name: String
    public var currencyId: Int64  // Foreign key reference
    public var purchasePrice: Double
    public var purchaseDate: Date
    public var usageRate: Double
    public var usageRatePeriodId: Int64
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: Int64? = nil,
        name: String,
        currencyId: Int64,
        purchasePrice: Double,
        purchaseDate: Date,
        usageRate: Double,
        usageRatePeriodId: Int64,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.currencyId = currencyId
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
        self.usageRate = usageRate
        self.usageRatePeriodId = usageRatePeriodId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Computed property to get elapsed days since purchase
    public var elapsedDays: Int {
        let days = Calendar.current.dateComponents([.day], from: purchaseDate, to: Date()).day ?? 0
        return max(days, 0)  // Avoid negative values
    }
    
    // Computed property to get accumulated cost
    public var accumulatedCost: Double {
        return usageRate * Double(elapsedDays)
    }
    
    // Computed property to get remaining cost
    public var remainingCost: Double {
        return max(purchasePrice - accumulatedCost, 0) // Avoid negative values
    }
    
    // Function to compute profit dynamically
    func calculateProfit(resalePrice: Double) -> Double {
        return resalePrice - remainingCost
    }
    
    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

extension Device {
    public static let currency = belongsTo(Currency.self, using: ForeignKey(["currencyId"]))
    public static let usageRatePeriod = belongsTo(UsageRatePeriod.self, using: ForeignKey(["usageRatePeriodId"]))
}

public struct Currency: Equatable, Codable, FetchableRecord, PersistableRecord, Sendable {
    public static let databaseTableName = "currencies"

    public var id: Int64?
    public var code: String  // "USD", "EUR"
    public var symbol: String  // "$", "€"
    public var name: String  // "US Dollar", "Euro"
    public var usdRate: Double  // Exchange rate to USD (1 unit of this currency = X USD)
    
    public init(id: Int64? = nil, code: String, symbol: String, name: String, usdRate: Double = 1.0) {
        self.id = id
        self.code = code
        self.symbol = symbol
        self.name = name
        self.usdRate = usdRate
    }
    
    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

public struct AppSettings: Equatable, Codable, FetchableRecord, PersistableRecord, Sendable {
    public static let databaseTableName = "app_settings"
    
    public var id: Int64?
    public var themeMode: String // "light", "dark", "system"
    public var defaultCurrencyId: Int64?
    public var notificationsEnabled: Bool
    public var updatedAt: Date
    
    public init(
        id: Int64? = nil,
        themeMode: String = "system",
        defaultCurrencyId: Int64? = nil,
        notificationsEnabled: Bool = true,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.themeMode = themeMode
        self.defaultCurrencyId = defaultCurrencyId
        self.notificationsEnabled = notificationsEnabled
        self.updatedAt = updatedAt
    }
}

extension AppSettings {
    public static let defaultCurrency = belongsTo(Currency.self, using: ForeignKey(["defaultCurrencyId"]))
}

#if DEBUG
extension Currency {
    public static let usd = Currency(id: 1, code: "USD", symbol: "$", name: "US Dollar", usdRate: 1.0)
    public static let eur = Currency(id: 2, code: "EUR", symbol: "€", name: "Euro", usdRate: 1.08)
    public static let gbp = Currency(id: 3, code: "GBP", symbol: "£", name: "British Pound", usdRate: 1.26)
    public static let jpy = Currency(id: 4, code: "JPY", symbol: "¥", name: "Japanese Yen", usdRate: 0.0067)
    public static let chf = Currency(id: 5, code: "CHF", symbol: "Fr", name: "Swiss Franc", usdRate: 1.13)
    public static let cad = Currency(id: 6, code: "CAD", symbol: "C$", name: "Canadian Dollar", usdRate: 0.73)
    public static let aud = Currency(id: 7, code: "AUD", symbol: "A$", name: "Australian Dollar", usdRate: 0.66)
}
#endif

// MARK: - Database Setup & Migrations
extension DatabaseWriter where Self == DatabaseQueue {
    public static var appDatabase: DatabaseQueue {
        let databaseQueue: DatabaseQueue
        var configuration = Configuration()
        configuration.prepareDatabase { db in
            
            db.trace(options: .profile) {
#if DEBUG
                print($0.expandedDescription)
#else
                print($0)
#endif
            }
        }
        
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == nil && !isTesting {
            let path = URL.documentsDirectory.appending(component: "db.sqlite").path()
            print("open", path)
            databaseQueue = try! DatabaseQueue(path: path, configuration: configuration)
        } else {
            databaseQueue = try! DatabaseQueue(configuration: configuration)
        }
        
        var migrator = DatabaseMigrator()
        
        migrator.registerMigration("Create \(UsageRatePeriod.databaseTableName) table") { db in
            try db.create(table: UsageRatePeriod.databaseTableName) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull().unique()  // "day", "week", "month", "year"
                t.column("daysMultiplier", .integer).notNull()  // Number of days in this period
            }
            
            // Insert predefined values
            try db.execute(sql:
            """
                INSERT INTO usage_rate_periods (name, daysMultiplier) VALUES
                ('day', 1),
                ('week', 7),
                ('month', 30),
                ('year', 365)
            """
            )
        }
        
        let usdId = LockIsolated<Int64?>(nil)
        let eurId = LockIsolated<Int64?>(nil)
        
        migrator.registerMigration("Create \(Currency.databaseTableName) table") { db in
            try db.create(table: Currency.databaseTableName) { tableau in
                tableau.autoIncrementedPrimaryKey("id")
                tableau.column("code", .text).notNull().unique()  // "USD", "EUR", "GBP"
                tableau.column("symbol", .text).notNull()         // "$", "€", "£"
                tableau.column("name", .text).notNull()           // "US Dollar", "Euro"
            }
            
            // Use direct SQL insertion instead of the Currency model to avoid the usdRate field
            try db.execute(sql: """
                INSERT INTO currencies (code, symbol, name) 
                VALUES ('USD', '$', 'US Dollar')
                """)
            let usdRow = try Row.fetchOne(db, sql: "SELECT id FROM currencies WHERE code = 'USD'")
            if let id = usdRow?["id"] as Int64? {
                usdId.setValue(id)
            }
            
            try db.execute(sql: """
                INSERT INTO currencies (code, symbol, name) 
                VALUES ('EUR', '€', 'Euro')
                """)
            let eurRow = try Row.fetchOne(db, sql: "SELECT id FROM currencies WHERE code = 'EUR'")
            if let id = eurRow?["id"] as Int64? {
                eurId.setValue(id)
            }
        }
        
        migrator.registerMigration("Create \(Device.databaseTableName) table") { db in
            try db.create(table: Device.databaseTableName) { tableau in
                tableau.autoIncrementedPrimaryKey("id")
                tableau.column("name", .text).notNull()                    // Device name
                tableau.column("currencyId", .integer)                 // Foreign key reference
                    .notNull()
                    .references(Currency.databaseTableName, onDelete: .cascade)
                tableau.column("purchasePrice", .double).notNull()          // Purchase price in dollars
                tableau.column("purchaseDate", .date).notNull()             // Date of purchase
                tableau.column("usageRate", .double).notNull()              // Daily/monthly usage rate
                tableau.column("usageRatePeriodId", .integer).notNull()
                    .references(UsageRatePeriod.databaseTableName, onDelete: .restrict)
                tableau.column("createdAt", .datetime).notNull()
                tableau.column("updatedAt", .datetime).notNull()
            }
            
            _ = try Device(
                name: "iPhone 14 Pro Max",
                currencyId: eurId.value!,
                purchasePrice: 1599.99,
                purchaseDate: Date(year: 2022, month: 9, day: 16),
                usageRate: 1,
                usageRatePeriodId: 1
            ).inserted(db)   
        }

        migrator.registerMigration("Add usdRate to currencies") { db in
            // First add the column
            try db.alter(table: Currency.databaseTableName) { t in
                t.add(column: "usdRate", .double).notNull().defaults(to: 1.0)
            }
            
            // Then update existing currencies with initial rates
            try db.execute(sql: """
                UPDATE currencies 
                SET usdRate = CASE 
                    WHEN code = 'USD' THEN 1.0
                    WHEN code = 'EUR' THEN 1.08
                    WHEN code = 'GBP' THEN 1.26
                    WHEN code = 'JPY' THEN 0.0067
                    ELSE 1.0
                END
                """)
        }
        
        migrator.registerMigration("Add more currencies") { db in
            // Add Japanese Yen
            try db.execute(sql: """
                INSERT INTO currencies (code, symbol, name, usdRate) 
                VALUES ('JPY', '¥', 'Japanese Yen', 0.0067)
                """)
                
            // Add Swiss Franc
            try db.execute(sql: """
                INSERT INTO currencies (code, symbol, name, usdRate) 
                VALUES ('CHF', 'Fr', 'Swiss Franc', 1.13)
                """)
                
            // Add British Pound
            try db.execute(sql: """
                INSERT INTO currencies (code, symbol, name, usdRate) 
                VALUES ('GBP', '£', 'British Pound', 1.26)
                """)
                
            // Add Canadian Dollar
            try db.execute(sql: """
                INSERT INTO currencies (code, symbol, name, usdRate) 
                VALUES ('CAD', 'C$', 'Canadian Dollar', 0.73)
                """)
                
            // Add Australian Dollar
            try db.execute(sql: """
                INSERT INTO currencies (code, symbol, name, usdRate) 
                VALUES ('AUD', 'A$', 'Australian Dollar', 0.66)
                """)
        }

        migrator.registerMigration("Create \(AppSettings.databaseTableName) table") { db in
            try db.create(table: AppSettings.databaseTableName) { tableau in
                tableau.autoIncrementedPrimaryKey("id")
                tableau.column("themeMode", .text).notNull().defaults(to: "system")
                tableau.column("defaultCurrencyId", .integer)
                    .references(Currency.databaseTableName, onDelete: .restrict)
                tableau.column("notificationsEnabled", .boolean).notNull().defaults(to: true)
                tableau.column("updatedAt", .datetime).notNull()
            }
            
            // Insert default settings
            try AppSettings(
                themeMode: "system",
                defaultCurrencyId: 1, // Default to USD
                notificationsEnabled: true
            ).insert(db)
            
            // Create a trigger to prevent deleting a currency if it's set as the default
            try db.execute(sql: """
                CREATE TRIGGER prevent_default_currency_deletion
                BEFORE DELETE ON \(Currency.databaseTableName)
                FOR EACH ROW
                WHEN EXISTS (SELECT 1 FROM \(AppSettings.databaseTableName) WHERE defaultCurrencyId = OLD.id)
                BEGIN
                    SELECT RAISE(ABORT, 'Cannot delete a currency that is set as default. Change the default currency first.');
                END;
            """)
        }
        
        // migrate make default currency id not nullable
      migrator.registerMigration("Make defaultCurrencyId non-nullable") { db in
        try db.create(table: "\(AppSettings.databaseTableName)_new") { table in
          table.autoIncrementedPrimaryKey("id")
          table.column("themeMode", .text).notNull().defaults(to: "system")
          table.column("defaultCurrencyId", .integer).notNull()
            .references(Currency.databaseTableName, onDelete: .restrict)
          table.column("notificationsEnabled", .boolean).notNull().defaults(to: true)
          table.column("updatedAt", .datetime).notNull()
        }

        // Copy data, setting a default value for `defaultCurrencyId` if necessary
        try db.execute(sql: """
        INSERT INTO \(AppSettings.databaseTableName)_new (id, themeMode, defaultCurrencyId, notificationsEnabled, updatedAt)
        SELECT id, themeMode, COALESCE(defaultCurrencyId, 1), notificationsEnabled, updatedAt FROM \(AppSettings.databaseTableName)
    """)

        // Drop old table
        try db.execute(sql: "DROP TABLE \(AppSettings.databaseTableName)")

        // Rename new table to match original
        try db.execute(sql: "ALTER TABLE \(AppSettings.databaseTableName)_new RENAME TO \(AppSettings.databaseTableName)")
      }

        migrator.insertSampleData()

        do {
#if DEBUG
            migrator.eraseDatabaseOnSchemaChange = true
#endif
            
            try migrator.migrate(databaseQueue)
        } catch {
            reportIssue(error)
        }
        return databaseQueue
    }
}

extension DatabaseMigrator {
    mutating func insertSampleData() {
        
        self.registerMigration("Add Sennheiser PXC 550") { db in
            _ = try Device(
                name: "Sennheiser PXC 550",
                currencyId: 1,
                purchasePrice: 500,
                purchaseDate: Date(year: 2016, month: 7, day: 10),
                usageRate: 10,
                usageRatePeriodId: UsageRatePeriod.month.id!
            ).inserted(db)
        }
        
        self.registerMigration("Add Anker 737 Power Bank") { db in
            _ = try Device(
                name: "Anker 737 Power Bank ",
                currencyId: 2,
                purchasePrice: 132.00,
                purchaseDate: Date(year: 2022, month: 11, day: 22),
                usageRate: 0.2,
                usageRatePeriodId: UsageRatePeriod.day.id!
            ).inserted(db)
        }
        
        self.registerMigration("Add Flow Mini Silver") { db in
            _ = try Device(
                name: "Flow Mini Silver",
                currencyId: 1,
                purchasePrice: 16.90,
                purchaseDate: Date(year: 2024, month: 11, day: 20),
                usageRate: 0.1,
                usageRatePeriodId: UsageRatePeriod.day.id!
            ).inserted(db)
        }
        
        self.registerMigration("Add ICEMAG 2") { db in
            _ = try Device(
                name: "ICEMAG 2 MagSafe Power Bank",
                currencyId: 1,
                purchasePrice: 69.90,
                purchaseDate: Date(year: 2024, month: 11, day: 20),
                usageRate: 0.1,
                usageRatePeriodId: UsageRatePeriod.day.id!
            ).inserted(db)
        }
        
        self.registerMigration("Add ICEMAG 1") { db in
            _ = try Device(
                name: "ICEMAG 1 MagSafe Power Bank",
                currencyId: 1,
                purchasePrice: 35.90,
                purchaseDate: Date(year: 2024, month: 11, day: 20),
                usageRate: 0.1,
                usageRatePeriodId: UsageRatePeriod.day.id!
            ).inserted(db)
        }
        
        self.registerMigration("Add Space Elevator") { db in
            _ = try Device(
                name: "Space Elevator Power Bank",
                currencyId: 1,
                purchasePrice: 19.99,
                purchaseDate: Date(year: 2024, month: 11, day: 20),
                usageRate: 0.1,
                usageRatePeriodId: UsageRatePeriod.day.id!
            ).inserted(db)
        }
        
        self.registerMigration("Add Shargeek 100") { db in
            _ = try Device(
                name: "Shargeek 100",
                currencyId: 1,
                purchasePrice: 159.00,
                purchaseDate: Date(year: 2023, month: 12, day: 09),
                usageRate: 0.2,
                usageRatePeriodId: UsageRatePeriod.day.id!
            ).inserted(db)
        }
    }
}
