import ComposableArchitecture
import Models
import SharingGRDB

@Reducer
public struct CurrencyRatesFeature: Sendable {

  @Reducer(state: .sendable, .equatable, action: .sendable, .equatable)
  public enum Destination: Equatable, Sendable {
    case alert(AlertState<Alert>)

    @CasePathable
    public enum Alert: Equatable, Sendable {
      case alertButtonTapped
    }
  }

  // Define a FetchKeyRequest for currencies with filtering
  public struct CurrencyFetcher: FetchKeyRequest {
    public typealias State = [Currency]

    public let searchTerm: String

    public init(searchTerm: String = "") {
      self.searchTerm = searchTerm
    }

    public func fetch(_ db: Database) throws -> [Currency] {
      // If searchTerm is empty, fetch all currencies
      if self.searchTerm.isEmpty {
        let result = try Currency.fetchAll(db)
        return result
      }

      // Otherwise, filter currencies at the database level
      // This uses SQL LIKE for case-insensitive prefix/contains matching
      let lowercaseSearch = self.searchTerm.lowercased()
      let sql = """
          SELECT * FROM currencies 
          WHERE LOWER(name) LIKE ? 
          OR LOWER(code) LIKE ? 
          ORDER BY code = 'USD' DESC, name
      """
      let pattern = "%\(lowercaseSearch)%"

      let result = try Currency.fetchAll(db, sql: sql, arguments: [pattern, pattern])
      return result
    }
  }

  @ObservableState
  public struct State: Equatable, Sendable {
    @Presents
    var destination: Destination.State?

    @Shared(.inMemory("currency_search"))
    var searchTerm: String = ""

    @SharedReader(.fetch(CurrencyFetcher()))
    public var currencies: [Currency]

    @SharedReader(.fetchOne(sql: "SELECT COUNT(*) FROM currencies"))
    public var totalCurrenciesCount: Int = 0

    public var showingAddCurrency = false
    public var isEditing = false

    public init() {}
  }

  public enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case destination(PresentationAction<Destination.Action>)
    case delegate(Delegate)
    case fetchCurrencyRates
    case updateCurrencyRates([Currency])
    case addCurrencyButtonTapped
    case addCurrencyCancelled
    case addCurrencySaved(Currency)
    case deleteCurrency(Int64)
    case showAlert(String)

    public enum Delegate: Equatable, Sendable {
      case didSaveSuccessfully
    }
  }

  @Dependency(\.defaultDatabase) var database
  @Dependency(\.dismiss) var dismiss

  public init() {}

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {

        case .binding(\.searchTerm):
          let newFilterTerm = state.searchTerm
          return .run { [state] _ in
            try await state.$currencies.load(.fetch(CurrencyFetcher(searchTerm: newFilterTerm)))
          }

        case .binding:
          return .none
        case .fetchCurrencyRates:
          return .run { [state] _ in
            try await state.$currencies.load(.fetch(CurrencyFetcher(searchTerm: state.searchTerm)))
          }

        case .delegate:
          return .none

        case let .updateCurrencyRates(rates):
          return .concatenate(
            .run { _ in
              try await database.write { db in
                for rate in rates {
                  if var currency = try Currency.fetchOne(db, key: ["id": rate.id!]) {
                    currency.usdRate = rate.usdRate
                    try currency.update(db)
                  }
                }
              }
            },
            .run { _ in await dismiss() }
          )

        case .addCurrencyButtonTapped:
          state.showingAddCurrency = true
          return .none

        case .addCurrencyCancelled:
          state.showingAddCurrency = false
          return .none

        case let .addCurrencySaved(currency):
          state.showingAddCurrency = false
          return .run { send in
            try await database.write { db in
              _ = try currency.inserted(db)
            }

            await send(.delegate(.didSaveSuccessfully))
          }

        case let .showAlert(message):
          state.destination = .alert(
            AlertState {
              TextState(message)
            } actions: {
              ButtonState(role: .cancel) {
                TextState(Strings.ok)
              }
            }
          )
          return .none

        case let .deleteCurrency(id):
          return .run { send in
            do {
              // First check if this is the default currency in a read transaction
              let isDefault = try await database.read { db in
                try Row.fetchOne(
                  db,
                  sql: "SELECT 1 FROM app_settings WHERE defaultCurrencyId = ?",
                  arguments: [id]
                ) != nil
              }

              // If it's the default currency, don't proceed with deletion but show alert
              if isDefault {
                await send(
                  .showAlert(Strings.cannotDeleteDefaultCurrency)
                )
                return
              }

              // If we're here, it's not the default currency, so proceed with deletion
              try await database.write { db in
                _ = try Currency.deleteOne(db, key: ["id": id])
              }
            } catch {
              await send(.showAlert(Strings.errorDeletingCurrency(error.localizedDescription)))
            }
          }

        case .destination:
          return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
}

extension AlertState where Action == CurrencyRatesFeature.Destination.Alert {
  static func show(_ message: String) -> Self {
    AlertState {
      TextState(message)
    } actions: {
      ButtonState(action: .alertButtonTapped) {
        TextState(Strings.ok)
      }
    }
  }
}
