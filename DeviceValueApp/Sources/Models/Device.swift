//
//  Device.swift
//  DeviceValueApp
//
//  Created by Ibrahim Kteish on 24/3/25.
//

import Foundation
import GRDB

public struct Device: Codable, Equatable, Identifiable, Sendable, FetchableRecord, MutablePersistableRecord {
  public static let databaseTableName = "devices"

  public var id: Int64?
  public var name: String
  public var currencyId: Int64 // Foreign key reference
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
    let days = Calendar.current.dateComponents([.day], from: self.purchaseDate, to: Date()).day ?? 0
    return max(days, 0) // Avoid negative values
  }

  // Computed property to get accumulated cost
  public var accumulatedCost: Double {
    self.usageRate * Double(self.elapsedDays)
  }

  // Computed property to get remaining cost
  public var remainingCost: Double {
    max(self.purchasePrice - self.accumulatedCost, 0) // Avoid negative values
  }

  // Function to compute profit dynamically
  func calculateProfit(resalePrice: Double) -> Double {
    resalePrice - self.remainingCost
  }

  public mutating func didInsert(_ inserted: InsertionSuccess) {
    self.id = inserted.rowID
  }
}

public extension Device {
  static let currency = belongsTo(Currency.self, using: ForeignKey(["currencyId"]))
  static let usageRatePeriod = belongsTo(UsageRatePeriod.self, using: ForeignKey(["usageRatePeriodId"]))
}
