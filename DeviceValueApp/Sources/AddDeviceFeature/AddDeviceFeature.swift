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
public struct AddDeviceFeature: Sendable {

  public enum Mode: Equatable, Sendable {
    case add
    case edit(Int64)

    var deviceId: Int64? {
      switch self {
        case .add:
          return nil
        case let .edit(id):
          return id
      }
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
    var mode: Mode

    @SharedReader(.fetchAll(sql: "SELECT * from \(Currency.databaseTableName)", animation: .default))
    public var currencies: [Currency]

    @SharedReader(.fetchAll(sql: "SELECT * from \(UsageRatePeriod.databaseTableName)", animation: .default))
    public var usageRatePeriods: [UsageRatePeriod]

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
      selectedUsageRatePeriodId: Int64 = 1 // Default to first period (day)
    ) {
      self.deviceName = deviceName
      self.selectedCurrencyId = selectedCurrencyId
      self.purchasePrice = purchasePrice
      self.purchaseDate = purchaseDate
      self.usageRate = usageRate
      self.selectedUsageRatePeriodId = selectedUsageRatePeriodId
      self.mode = .add
    }

    public init(with device: Device, mode: Mode) {
      self.deviceName = device.name
      self.selectedCurrencyId = device.currencyId
      self.purchasePrice = String(device.purchasePrice)
      self.purchaseDate = device.purchaseDate
      self.usageRate = String(device.usageRate)
      self.selectedUsageRatePeriodId = device.usageRatePeriodId
      self.mode = mode
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
      case didUpdateDevice(Device)
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
            id: state.mode.deviceId,
            name: state.deviceName,
            currencyId: state.selectedCurrencyId,
            purchasePrice: price,
            purchaseDate: state.purchaseDate,
            usageRate: rate,
            usageRatePeriodId: state.selectedUsageRatePeriodId
          )
          let mode = state.mode
          return .run { send in
            try await database.write { db in
              var device_ = device
              if mode == .add {
                _ = try device_.insert(db)
              } else {
                try device_.update(db)
              }
            }

            if mode == .add {
              await send(.delegate(.didAddDevice(device)))
            } else {
              await send(.delegate(.didUpdateDevice(device)))
            }
            await dismiss()
          }
        case .delegate:
          return .none
      }
    }
  }
}
