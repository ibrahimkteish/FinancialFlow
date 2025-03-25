//
//  Models.swift
//  DeviceValueApp
//
//  Created by Ibrahim Koteish on 15/2/25.
//

import ConcurrencyExtras
import Foundation
import GRDB
import IssueReporting
import Sharing
import Utils

// MARK: - Database Setup & Migrations

public extension DatabaseWriter where Self == DatabaseQueue {
  static var appDatabase: DatabaseQueue {
    let databaseQueue: DatabaseQueue
    var configuration = Configuration()
    configuration.prepareDatabase { db in

      db.trace(options: .profile) {
        #if DEBUG
        print($0.expandedDescription)
        #else
        #endif
      }
    }

    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == nil, !isTesting {
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
        t.column("name", .text).notNull().unique() // "day", "week", "month", "year"
        t.column("daysMultiplier", .integer).notNull() // Number of days in this period
      }

      // Insert predefined values
      try db.execute(
        sql:
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
        tableau.column("code", .text).notNull().unique() // "USD", "EUR", "GBP"
        tableau.column("symbol", .text).notNull() // "$", "€", "£"
        tableau.column("name", .text).notNull() // "US Dollar", "Euro"
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
        tableau.column("name", .text).notNull() // Device name
        tableau.column("currencyId", .integer) // Foreign key reference
          .notNull()
          .references(Currency.databaseTableName, onDelete: .cascade)
        tableau.column("purchasePrice", .double).notNull() // Purchase price in dollars
        tableau.column("purchaseDate", .date).notNull() // Date of purchase
        tableau.column("usageRate", .double).notNull() // Daily/monthly usage rate
        tableau.column("usageRatePeriodId", .integer).notNull()
          .references(UsageRatePeriod.databaseTableName, onDelete: .restrict)
        tableau.column("createdAt", .datetime).notNull()
        tableau.column("updatedAt", .datetime).notNull()
      }
      #if DEBUG
      _ = try Device(
        name: "iPhone 14 Pro Max",
        currencyId: eurId.value!,
        purchasePrice: 1599.99,
        purchaseDate: Date(year: 2022, month: 9, day: 16),
        usageRate: 2,
        usageRatePeriodId: 1
      ).inserted(db)
      #endif
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
          WHEN code = 'EUR' THEN 0.9236
          WHEN code = 'GBP' THEN 0.7733
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
          INSERT INTO \(AppSettings
        .databaseTableName)_new (id, themeMode, defaultCurrencyId, notificationsEnabled, updatedAt)
          SELECT id, themeMode, COALESCE(defaultCurrencyId, 1), notificationsEnabled, updatedAt FROM \(AppSettings
        .databaseTableName)
      """)

      // Drop old table
      try db.execute(sql: "DROP TABLE \(AppSettings.databaseTableName)")

      // Rename new table to match original
      try db
        .execute(sql: "ALTER TABLE \(AppSettings.databaseTableName)_new RENAME TO \(AppSettings.databaseTableName)")
    }
    #if DEBUG
    migrator.insertSampleData()
    #endif
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

#if DEBUG
extension DatabaseMigrator {
  mutating func insertSampleData() {

    self.registerMigration("Add iPhone 15 Pro Max") { db in
      _ = try Device(
        name: "iPhone 15 Pro Max",
        currencyId: 1,
        purchasePrice: 1199.00,
        purchaseDate: Date(year: 2023, month: 9, day: 22),
        usageRate: 10,
        usageRatePeriodId: UsageRatePeriod.month.id!
      ).inserted(db)
    }

    self.registerMigration("Add MacBook Pro 16-inch") { db in
      _ = try Device(
        name: "MacBook Pro 16-inch M3",
        currencyId: 2,
        purchasePrice: 2499.00,
        purchaseDate: Date(year: 2023, month: 10, day: 30),
        usageRate: 0.2,
        usageRatePeriodId: UsageRatePeriod.day.id!
      ).inserted(db)
    }

    self.registerMigration("Add iPad Pro 12.9-inch") { db in
      _ = try Device(
        name: "iPad Pro 12.9-inch M2",
        currencyId: 1,
        purchasePrice: 1099.00,
        purchaseDate: Date(year: 2023, month: 6, day: 12),
        usageRate: 0.1,
        usageRatePeriodId: UsageRatePeriod.day.id!
      ).inserted(db)
    }

    self.registerMigration("Add Apple Watch Series 9") { db in
      _ = try Device(
        name: "Apple Watch Series 9",
        currencyId: 1,
        purchasePrice: 399.00,
        purchaseDate: Date(year: 2023, month: 9, day: 22),
        usageRate: 0.1,
        usageRatePeriodId: UsageRatePeriod.day.id!
      ).inserted(db)
    }

    self.registerMigration("Add AirPods Pro 2") { db in
      _ = try Device(
        name: "AirPods Pro 2",
        currencyId: 1,
        purchasePrice: 249.00,
        purchaseDate: Date(year: 2022, month: 9, day: 23),
        usageRate: 0.1,
        usageRatePeriodId: UsageRatePeriod.day.id!
      ).inserted(db)
    }

    self.registerMigration("Add Mac Studio M2 Max") { db in
      _ = try Device(
        name: "Mac Studio M2 Max",
        currencyId: 1,
        purchasePrice: 1999.00,
        purchaseDate: Date(year: 2023, month: 6, day: 5),
        usageRate: 0.1,
        usageRatePeriodId: UsageRatePeriod.day.id!
      ).inserted(db)
    }

    self.registerMigration("Add Apple Vision Pro") { db in
      _ = try Device(
        name: "Apple Vision Pro",
        currencyId: 1,
        purchasePrice: 3499.00,
        purchaseDate: Date(year: 2024, month: 2, day: 2),
        usageRate: 0.2,
        usageRatePeriodId: UsageRatePeriod.day.id!
      ).inserted(db)
    }
  }
}
#endif
