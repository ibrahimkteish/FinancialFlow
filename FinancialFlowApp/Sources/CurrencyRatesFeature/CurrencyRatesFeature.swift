import ComposableArchitecture
import Models
import SharingGRDB

@Reducer
public struct CurrencyRatesReducer: Sendable {

  // Define a FetchKeyRequest for currencies with filtering
  public struct CurrencyFetcher: FetchKeyRequest {
    public typealias State = [Currency]

    public let searchTerm: String

    public init(searchTerm: String = "") {
      self.searchTerm = searchTerm
    }

    public func fetch(_ db: Database) throws -> [Currency] {
      print("Fetching currencies from database with search term: \(searchTerm)")

      // If searchTerm is empty, fetch all currencies
      if searchTerm.isEmpty {
        let result = try Currency.fetchAll(db)
        print("Fetched \(result.count) currencies")
        return result
      }

      // Otherwise, filter currencies at the database level
      // This uses SQL LIKE for case-insensitive prefix/contains matching
      let lowercaseSearch = searchTerm.lowercased()
      let sql = """
                SELECT * FROM currencies 
                WHERE LOWER(name) LIKE ? 
                OR LOWER(code) LIKE ? 
                ORDER BY code = 'USD' DESC, name
            """
      let pattern = "%\(lowercaseSearch)%"

      let result = try Currency.fetchAll(db, sql: sql, arguments: [pattern, pattern])
      print("Fetched \(result.count) filtered currencies")
      return result
    }
  }

  @ObservableState
  public struct State: Equatable, Sendable {
    @Shared(.inMemory("currency_search"))
    var searchTerm: String = ""

    @SharedReader(.fetch(CurrencyFetcher()))
    public var currencies: [Currency]

    public var showingAddCurrency = false
    public var isEditing = false

    public init() {}
  }

  public enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case fetchCurrencyRates
    case updateCurrencyRates([Currency])
    case addCurrencyButtonTapped
    case addCurrencyCancelled
    case addCurrencySaved(Currency)
    case deleteCurrency(Int64)
  }

  @Dependency(\.defaultDatabase) var database

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

        case let .updateCurrencyRates(rates):
          return .run { _ in
            try await database.write { db in
              for rate in rates {
                if var currency = try Currency.fetchOne(db, key: ["id": rate.id!]) {
                  currency.usdRate = rate.usdRate
                  try currency.update(db)
                }
              }
            }
            // No need to call fetchCurrencyRates as SharedReader will auto-update
          }

        case .addCurrencyButtonTapped:
          state.showingAddCurrency = true
          return .none

        case .addCurrencyCancelled:
          state.showingAddCurrency = false
          return .none

        case let .addCurrencySaved(currency):
          state.showingAddCurrency = false
          return .run { _ in
            try await database.write { db in
              _ = try currency.inserted(db)
            }
            // No need to call fetchCurrencyRates as SharedReader will auto-update
          }

        case let .deleteCurrency(id):
          return .run { send in
            do {
              try await database.write { db in
                // Check if this is the default currency
                let isDefault = try Row.fetchOne(db, 
                  sql: "SELECT 1 FROM app_settings WHERE defaultCurrencyId = ?", 
                  arguments: [id]) != nil
                
                if isDefault {
                  // If it's the default currency, throw an error
                  throw NSError(
                    domain: "com.financialflow.error",
                    code: 1001,
                    userInfo: [NSLocalizedDescriptionKey: "Cannot delete the default currency. Change the default currency in Settings first."]
                  )
                }
                
                // If it's not the default currency, proceed with deletion
                _ = try Currency.deleteOne(db, key: ["id": id])
              }
            } catch {
              print("Error deleting currency: \(error.localizedDescription)")
              // You could send an error action here if you want to display the error to the user
            }
          }
      }
    }
  }
}
