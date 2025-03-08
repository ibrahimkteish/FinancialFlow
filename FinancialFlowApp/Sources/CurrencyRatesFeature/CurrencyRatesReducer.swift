import ComposableArchitecture
import Models
import SharingGRDB

@Reducer
public struct CurrencyRatesReducer: Sendable {

    // Define a FetchKeyRequest for currencies
    public struct CurrencyFetcher: FetchKeyRequest {
        public typealias State = [Currency]
        
        public func fetch(_ db: Database) throws -> State {
            let result = try Currency.fetchAll(db)
            return result
        }
    }
    
    @ObservableState
    public struct State: Equatable, Sendable {
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
            case .binding:
                return Effect<Action>.none

            case .fetchCurrencyRates:
                return .run { [state] _ in
                  try await state.$currencies.load(.fetch(CurrencyRatesReducer.CurrencyFetcher()))
                }
                
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
                }
                
            case let .deleteCurrency(id):
                return .run { send in
//                    try await database.write { db in
//                      try Currency.deleteOne(db, key: id)
//                    }
                }
            }
        }
    }
} 
