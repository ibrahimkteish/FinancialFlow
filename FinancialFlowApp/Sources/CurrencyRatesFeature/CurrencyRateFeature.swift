import SwiftUI
import ComposableArchitecture

public struct CurrencyRateView: View {
    @Bindable var store: StoreOf<CurrencyRateReducer>
    
    public init(store: StoreOf<CurrencyRateReducer>) {
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
            initialState: CurrencyRateReducer.State()
        ) {
            CurrencyRateReducer()
        }
    )
} 