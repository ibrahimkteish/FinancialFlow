// AddDeviceFeature.swift
// created by: @ibrahim koteish
// created at: 2025-02-18

import ComposableArchitecture
import Foundation
import Generated
import GRDB
import Models
import SharingGRDB

extension UsageRatePeriod {
  var localizedName: String {
    switch self.name {
      case "day":
        return Strings.day
      case "week":
        return Strings.week
      case "month":
        return Strings.month
      case "year":
        return Strings.year
      default:
        return "day"
    }
  }
}

@Reducer
public struct AddDeviceReducer: Sendable {
  // Define a FetchKeyRequest for currencies
  public struct CurrencyFetcher: FetchKeyRequest {
    public typealias State = [Currency]

    public init() {}

    public func fetch(_ db: Database) throws -> [Currency] {
      let result = try Currency.fetchAll(db, sql: """
          SELECT * FROM currencies
          ORDER BY code = 'USD' DESC, name
      """)
      return result
    }
  }

  @ObservableState
  public struct State: Equatable, Sendable {
    var deviceName: String
    var selectedCurrencyId: Int64
    var purchasePrice: String
    var purchaseDate: Date
    var usageRate: String
    var selectedUsageRatePeriodId: Int64

    @SharedReader(.fetchAll(sql: "SELECT * from \(Currency.databaseTableName)", animation: .default))
    public var currencies: [Currency]

    var usageRatePeriods: [UsageRatePeriod]
    var isValid: Bool {
      !self.deviceName.isEmpty &&
        Double(self.purchasePrice) != nil &&
        Double(self.usageRate) != nil
    }

    public init(
      deviceName: String = "",
      selectedCurrencyId: Int64 = 1, // Default to first currency
      purchasePrice: String = "",
      purchaseDate: Date = .now,
      usageRate: String = "",
      selectedUsageRatePeriodId: Int64 = 1, // Default to first period (day)
      usageRatePeriods: [UsageRatePeriod] = [.day, .week, .month, .year]
    ) {
      self.deviceName = deviceName
      self.selectedCurrencyId = selectedCurrencyId
      self.purchasePrice = purchasePrice
      self.purchaseDate = purchaseDate
      self.usageRate = usageRate
      self.selectedUsageRatePeriodId = selectedUsageRatePeriodId
      self.usageRatePeriods = usageRatePeriods
    }
  }

  public enum Action: BindableAction, Equatable, Sendable {
    case binding(BindingAction<State>)
    case submitButtonTapped
    case cancelButtonTapped
    case addCurrencyTapped
    case delegate(Delegate)

    @CasePathable
    public enum Delegate: Equatable, Sendable {
      case didAddDevice(Device)
      case dismiss
      case addCurrency
    }
  }

  @Dependency(\.dismiss) var dismiss
  @Dependency(\.defaultDatabase) var database

  public init() {}

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        case .binding:
          return .none

        case .cancelButtonTapped:
          return .run { _ in
            await dismiss()
          }

        case .addCurrencyTapped:
          return .send(.delegate(.addCurrency))

        case .submitButtonTapped:
          guard
            let price = Double(state.purchasePrice),
            let rate = Double(state.usageRate)
          else {
            return .none
          }

          let device = Device(
            name: state.deviceName,
            currencyId: state.selectedCurrencyId,
            purchasePrice: price,
            purchaseDate: state.purchaseDate,
            usageRate: rate,
            usageRatePeriodId: state.selectedUsageRatePeriodId
          )

          return .run { send in
            try await database.write { db in
              var device_ = device
              _ = try device_.insert(db)
            }
            await send(.delegate(.didAddDevice(device)))
            await dismiss()
          }

        case .delegate:
          return .none
      }
    }
  }
}
