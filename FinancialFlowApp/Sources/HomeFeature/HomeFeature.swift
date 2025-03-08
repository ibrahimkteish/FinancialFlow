//
//  HomeFeature.swift
//  FinancialFlowApp
//
//  Created by Ibrahim Koteish on 15/2/25.
//

import ComposableArchitecture
import Models
import SharingGRDB
import AddDeviceFeature
import AnalyticsFeature

public struct CurrencyCost: FetchableRecord, Decodable, Equatable, Sendable {
  let currencyCode: String
  let totalDailyCost: Double

  init(currencyCode: String, totalDailyCost: Double) {
    self.currencyCode = currencyCode
    self.totalDailyCost = totalDailyCost
  }
}

@Reducer
public struct HomeReducer: Sendable {

  @Reducer(state: .equatable, .sendable, action: .equatable, .sendable)
  public enum Destination {
    case addDevice(AddDeviceReducer)
    case analytics(Analytics)
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
    public var currencies: [Currency] = []
    
    public var showingCurrencyRates = false

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
  }

  public struct Items: FetchKeyRequest {
    public let ordering: Ordering
    public struct State: Equatable, Sendable  {

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
        .order(ordering.orderingTerm)

      // Execute the query and map results
      return try Row.fetchAll(db, sql).map { row in
        State(device: try Device(row: row), currency: row["currency"], usageRatePeriod: row["usage_rate_period"])
      }
    }
  }
  public struct Aggregate: FetchKeyRequest {

    public typealias State = CurrencyCost?

    public func fetch(_ db: Database) throws -> State {
      // Use raw SQL to join the tables
      let sql =
             """
             SELECT 
                 c.code AS currency_code,
                 SUM(d.usageRate * c.usdRate / urp.daysMultiplier) AS total_daily_cost
             FROM devices d
             JOIN currencies c ON d.currencyId = c.id
             JOIN usage_rate_periods urp ON d.usageRatePeriodId = urp.id
             GROUP BY c.code;
             """

      // Execute the query and map results
      return try Row.fetchOne(db, sql: sql).map { row in
        let currencyCode: String = row["currency_code"]
        let totalDailyCost: Double = row["total_daily_cost"]
        return .init(currencyCode: currencyCode, totalDailyCost: totalDailyCost)
      }
    }
  }

  public enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case addDeviceButtonTapped
    case analyticsButtonTapped
    case currencyRatesButtonTapped
    case cancelAddDeviceButtonTapped
    case destination(PresentationAction<Destination.Action>)
    case removeDevice(Int64)
    case onAppear
    case onSortChanged(Ordering)
    case submitButtonTapped
    case fetchCurrencyRates
    case currencyRatesResponse([Currency])
    case updateCurrencyRates([Currency])
  }

  @Dependency(\.defaultDatabase) var database

  public init() {}

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        case .binding:
          return .none
        case .addDeviceButtonTapped:
          state.destination = .addDevice(AddDeviceReducer.State())
          return .none

        case .analyticsButtonTapped:
          state.destination = .analytics(Analytics.State())
          return .none

        case .currencyRatesButtonTapped:
          state.showingCurrencyRates = true
          return .run { send in
            await send(.fetchCurrencyRates)
          }

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
          return .run { send in
            await send(.fetchCurrencyRates)
          }

        case let .onSortChanged(newSort):
          state.$ordering.withLock { $0 = newSort }
          return .run { [state] _ in
            try await state.$devices.load(.fetch(HomeReducer.Items(ordering: state.ordering)))
          }

        case .submitButtonTapped:
          state.destination = nil
          return .none

        case .fetchCurrencyRates:
          return .run { send in
            do {
              let currencies = try await database.read { db in
                print("Fetching currencies from database...")
                return try Currency.fetchAll(db)
              }
              print("Fetched \(currencies.count) currencies")
              await send(.currencyRatesResponse(currencies))
            } catch {
              print("Error fetching currencies: \(error)")
            }
          }

        case let .currencyRatesResponse(currencies):
          print("Setting currencies in state: \(currencies.count)")
          state.currencies = currencies
          return .none

        case let .updateCurrencyRates(rates):
          return .run { send in
            try await database.write { db in
              for rate in rates {
                if var currency = try Currency.fetchOne(db, key: ["id": rate.id!]) {
                  currency.usdRate = rate.usdRate
                  try currency.update(db)
                }
              }
            }
            await send(.fetchCurrencyRates)
          }

        case .destination:
          return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
}
