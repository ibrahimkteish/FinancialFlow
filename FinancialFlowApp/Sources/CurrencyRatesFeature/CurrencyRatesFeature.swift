import SwiftUI
import ComposableArchitecture

public struct CurrencyRateView: View {
    @Bindable var store: StoreOf<CurrencyRatesReducer>

    public init(store: StoreOf<CurrencyRatesReducer>) {
        self.store = store
    }
    
    public var body: some View {
        NavigationStack {
            CurrencyRatesView(store: store)
                .sheet(
                    isPresented: $store.showingAddCurrency
                ) {
                    AddCurrencyView(store: store)
                }
                .task {
                    await store.send(.fetchCurrencyRates)
                }
        }
    }
}

#Preview {
    CurrencyRateView(
        store: Store(
            initialState: CurrencyRatesReducer.State()
        ) {
            CurrencyRatesReducer()
        }
    )
} 
