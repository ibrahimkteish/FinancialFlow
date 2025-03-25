//
//  Currency.swift
//  DeviceValueApp
//
//  Created by Ibrahim Kteish on 24/3/25.
//

import GRDB

public struct Currency: Equatable, Codable, FetchableRecord, PersistableRecord, Sendable {
  public static let databaseTableName = "currencies"

  public var id: Int64?
  public var code: String // "USD", "EUR"
  public var symbol: String // "$", "€"
  public var name: String // "US Dollar", "Euro"
  public var usdRate: Double // Exchange rate to USD (1 unit of this currency = X USD)

  public init(id: Int64? = nil, code: String, symbol: String, name: String, usdRate: Double = 1.0) {
    self.id = id
    self.code = code
    self.symbol = symbol
    self.name = name
    self.usdRate = usdRate
  }

  public mutating func didInsert(_ inserted: InsertionSuccess) {
    self.id = inserted.rowID
  }
}

public extension Currency {
  static let usd = Currency(id: 1, code: "USD", symbol: "$", name: "US Dollar", usdRate: 1.0)
}

#if DEBUG
public extension Currency {
  static let eur = Currency(id: 2, code: "EUR", symbol: "€", name: "Euro", usdRate: 0.9237)
  static let gbp = Currency(id: 3, code: "GBP", symbol: "£", name: "British Pound", usdRate: 0.7736)
  static let jpy = Currency(
    id: 4,
    code: "JPY",
    symbol: "¥",
    name: "Japanese Yen",
    usdRate: 0.0067
  ) // 1 JPY = 0.0067 USD
  static let chf = Currency(id: 5, code: "CHF", symbol: "Fr", name: "Swiss Franc", usdRate: 0.8824)
  static let cad = Currency(id: 6, code: "CAD", symbol: "C$", name: "Canadian Dollar", usdRate: 1.4348)
  static let aud = Currency(id: 7, code: "AUD", symbol: "A$", name: "Australian Dollar", usdRate: 1.5933)
}
#endif
