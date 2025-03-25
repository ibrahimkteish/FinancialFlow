//
//  AppSettings.swift
//  DeviceValueApp
//
//  Created by Ibrahim Kteish on 24/3/25.
//

import Foundation
import GRDB

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

public extension AppSettings {
  static let defaultCurrency = belongsTo(Currency.self, using: ForeignKey(["defaultCurrencyId"]))
}
