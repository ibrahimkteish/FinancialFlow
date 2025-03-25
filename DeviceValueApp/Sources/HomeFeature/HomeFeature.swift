//
//  HomeFeature.swift
//  DeviceValueApp
//
//  Created by Ibrahim Koteish on 15/2/25.
//

import AddDeviceFeature
import AnalyticsFeature
import ComposableArchitecture
import CurrencyRatesFeature
import Generated
import Models
import SettingsFeature
import SharingGRDB

public struct CurrencyCost: FetchableRecord, Decodable, Equatable, Sendable {
  let currencyCode: String
  let totalDailyCost: Double

  init(currencyCode: String, totalDailyCost: Double) {
    self.currencyCode = currencyCode
    self.totalDailyCost = totalDailyCost
  }
}

@Reducer
public struct HomeFeature: Sendable {

  @Reducer(state: .equatable, .sendable, action: .equatable, .sendable)
  public enum Path {
    case settings(SettingsFeature)
    case currencyRates(CurrencyRatesFeature)
  }

  @Reducer(state: .equatable, .sendable, action: .equatable, .sendable)
  public enum Destination {
    case addDevice(AddDeviceFeature)
    case analytics(Analytics)
    case addCurrency(CurrencyRatesFeature)
  }

  @ObservableState
  public struct State: Equatable, Sendable {

    @Presents
    public var destination: Destination.State?

    @SharedReader(.fetch(Items(ordering: .created)))
    public var devices: [Items.State]
    @Shared(.inMemory("order"))
    var ordering: Ordering = .created
    @SharedReader(.fetch(Aggregate()))
    public var count: CurrencyCost? = nil

    @SharedReader(.fetch(SettingsFeature.SettingsFetcher()))
    public var settingsWithCurrency: AppSettingsWithCurrency = .init()

    var path = StackState<Path.State>()

    public init() {}
  }

  public enum Ordering: String, Equatable, Sendable, CaseIterable {
    case created = "CreatedAt"
    case currency = "Currency"
    case name = "Name"
    case price = "PurchasePrice"
    case updatedAt = "UpdatedAt"

    var orderingTerm: any SQLOrderingTerm & Sendable {
      switch self {
        case .updatedAt: return Column("updatedAt")
        case .created: return Column("createdAt")
        case .name: return Column("name")
        case .currency: return Column("currencyId")
        case .price: return Column("purchasePrice")
      }
    }

    var localizedName: String {
      switch self {
        case .created: return Strings.createdAt
        case .updatedAt: return Strings.updatedAt
        case .name: return Strings.name
        case .currency: return Strings.currency
        case .price: return Strings.purchasePrice
      }
    }
  }

  public struct Items: FetchKeyRequest {
    public let ordering: Ordering
    public struct State: Equatable, Sendable {

      public var id: Int64? {
        self.device.id
      }

      public let device: Device
      public let currency: Currency
      public let usageRatePeriod: UsageRatePeriod

      public init(
        device: Device,
        currency: Currency,
        usageRatePeriod: UsageRatePeriod
      ) {
        self.device = device
        self.currency = currency
        self.usageRatePeriod = usageRatePeriod
      }
    }

    public init(ordering: Ordering) {
      self.ordering = ordering
    }

    public func fetch(_ db: Database) throws -> [State] {
      // Use raw SQL to join the tables
      let sql = Device.all()
        .including(required: Device.currency)
        .including(required: Device.usageRatePeriod)
        .order(self.ordering.orderingTerm)

      // Execute the query and map results
      return try Row.fetchAll(db, sql).map { row in
        State(device: try Device(row: row), currency: row["currency"], usageRatePeriod: row["usage_rate_period"])
      }
    }
  }

  public struct Aggregate: FetchKeyRequest {

    public typealias State = CurrencyCost?

    public func fetch(_ db: Database) throws -> State {
      // First get the default currency from settings
      let settingsRow = try Row.fetchOne(db, sql: "SELECT defaultCurrencyId FROM app_settings LIMIT 1")

      // If no default currency is set, fall back to USD
      let defaultCurrencyId: Int64
      if let settingsCurrencyId = settingsRow?["defaultCurrencyId"] as? Int64 {
        defaultCurrencyId = settingsCurrencyId
      } else {
        // Find USD as fallback
        let usdRow = try Row.fetchOne(db, sql: "SELECT id FROM currencies WHERE code = 'USD' LIMIT 1")
        defaultCurrencyId = usdRow?["id"] as? Int64 ?? 1 // Fallback to ID 1 if USD not found
      }

      // In our database, usdRate represents how many units of a currency equals 1 USD
      // So for USD, usdRate = 1.0
      // For EUR, if usdRate = 0.92 (meaning 0.92 EUR = 1 USD)
      // For JPY, if usdRate = 108 (meaning 108 JPY = 1 USD)
      // To convert from any currency to USD:
      // - We multiply by (1.0 / usdRate): e.g., 1 EUR * (1/0.92) = 1.08 USD or 1 JPY * (1/108) = 0.0093 USD
      let sql = """
          WITH total_in_usd AS (
              -- First convert everything to USD (multiply by the inverse of usdRate for non-USD currencies)
              SELECT SUM(
                  CASE 
                      WHEN c.code = 'USD' THEN d.usageRate 
                      ELSE d.usageRate * (1.0 / c.usdRate)
                  END / urp.daysMultiplier
              ) AS usd_total
              FROM devices d
              JOIN currencies c ON d.currencyId = c.id
              JOIN usage_rate_periods urp ON d.usageRatePeriodId = urp.id
          )
          SELECT 
              c.code AS currency_code,
              COALESCE(CASE 
                  -- For USD, return as is
                  WHEN c.code = 'USD' THEN tu.usd_total
                  -- For other currencies, convert from USD to target currency
                  -- If target currency's usdRate is X (meaning X units = 1 USD)
                  -- Then to convert USD to that currency, we multiply by usdRate:
                  -- For example: 3.18 USD * 0.92 = 2.93 EUR or 3.18 USD * 108 = 343.44 JPY
                  ELSE tu.usd_total * c.usdRate
              END, 0) AS total_daily_cost
          FROM total_in_usd tu
          JOIN currencies c ON c.id = ?
      """

      // Execute the query and map results
      return try Row.fetchOne(db, sql: sql, arguments: [defaultCurrencyId]).map { row in
        let currencyCode: String = row["currency_code"]
        let totalDailyCost: Double = row["total_daily_cost"]
        return .init(currencyCode: currencyCode, totalDailyCost: totalDailyCost)
      }
    }
  }

  public enum Action: Equatable, BindableAction {
    case analyticsButtonTapped
    case addDeviceButtonTapped
    case addCurrencyButtonTapped
    case binding(BindingAction<State>)
    case cancelAddDeviceButtonTapped
    case destination(PresentationAction<Destination.Action>)
    case onAppear
    case onSortChanged(Ordering)
    case path(StackAction<Path.State, Path.Action>)
    case removeDevice(Int64)
    case settingsButtonTapped
    case submitButtonTapped
  }

  @Dependency(\.defaultDatabase) var database
  @Dependency(\.applicationClient) var applicationClient

  public init() {}

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        case .binding:
          return .none
        case .addDeviceButtonTapped:
          state.destination = .addDevice(AddDeviceFeature.State())
          return .none

        case .addCurrencyButtonTapped:
          state.destination = .addCurrency(CurrencyRatesFeature.State())
          return .none

        case .analyticsButtonTapped:
          state.destination = .analytics(Analytics.State())
          return .none

        case .cancelAddDeviceButtonTapped:
          state.destination = nil
          return .none

        case let .removeDevice(id):
          return .run { _ in
            _ = try await database.write { db in
              try Device.deleteOne(db, id: id)
            }
          }

        case .onAppear:
          return .run { [state] _ in
            // Apply theme from settings
            let savedTheme = SettingsFeature
              .AppTheme(rawValue: state.settingsWithCurrency.settings.themeMode) ?? .system
            await applicationClient.setUserInterfaceStyle(savedTheme.userInterfaceStyle)
          }

        case let .onSortChanged(newSort):
          state.$ordering.withLock { $0 = newSort }
          return .run { [state] _ in
            try await state.$devices.load(.fetch(HomeFeature.Items(ordering: state.ordering)))
          }
        case let .path(.element(id: _, action: .settings(.delegate(delAction)))):
          switch delAction {
            case .currencyRatesTapped:
              state.path.append(.currencyRates(CurrencyRatesFeature.State()))
          }
          return .none

        case .path:
          return .none

        case .settingsButtonTapped:
          state.path.append(.settings(SettingsFeature.State()))
          return .none

        case .submitButtonTapped:
          state.destination = nil
          return .none

        case let .destination(.presented(.addDevice(.delegate(action)))):
          switch action {
            case .dismiss:
              state.destination = nil
            case .didAddDevice:
              state.destination = nil
            case .addCurrency:
              state.destination = .addCurrency(CurrencyRatesFeature.State())
          }
          return .none

        case let .destination(.presented(.addCurrency(.delegate(action)))):
          switch action {
            case .didSaveSuccessfully:
              state.destination = .addDevice(AddDeviceFeature.State())
          }
          return .none

        case .destination:
          return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
    .forEach(\.path, action: \.path)
  }
}
