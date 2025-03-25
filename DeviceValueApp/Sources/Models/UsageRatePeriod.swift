//
//  UsageRatePeriod.swift
//  DeviceValueApp
//
//  Created by Ibrahim Kteish on 24/3/25.
//

import GRDB

public struct UsageRatePeriod: Equatable, Codable, FetchableRecord, PersistableRecord, Sendable {
  public static let databaseTableName = "usage_rate_periods"

  public var id: Int64?
  public var name: String // "day", "week", "month", "year"
  public var daysMultiplier: Int // 1 for day, 7 for week, etc.

  public init(id: Int64? = nil, name: String, daysMultiplier: Int) {
    self.id = id
    self.name = name
    self.daysMultiplier = daysMultiplier
  }
}

public extension UsageRatePeriod {
  static let day = UsageRatePeriod(id: 1, name: "day", daysMultiplier: 1)
  static let week = UsageRatePeriod(id: 2, name: "week", daysMultiplier: 7)
  static let month = UsageRatePeriod(id: 3, name: "month", daysMultiplier: 30)
  static let year = UsageRatePeriod(id: 4, name: "year", daysMultiplier: 365)
}
