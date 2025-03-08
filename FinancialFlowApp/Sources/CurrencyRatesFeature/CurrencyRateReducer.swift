import ComposableArchitecture
import Models
import SharingGRDB

@Reducer
public struct CurrencyRateReducer: Sendable {
    
    @ObservableState
    public struct State: Equatable, Sendable {
        public var currencies: [Currency] = []
        public var showingAddCurrency = false
        public var isEditing = false
        
        public init(currencies: [Currency] = []) {
            self.currencies = currencies
        }
    }
    
    public enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case fetchCurrencyRates
        case currencyRatesResponse([Currency])
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
                    await send(.fetchCurrencyRates)
                }
                
            case let .deleteCurrency(id):
                return .run { send in
                    try await database.write { db in
//                        try Currency.deleteOne(db, id: id)
                    }
                    await send(.fetchCurrencyRates)
                }
            }
        }
    }
} 
