import SwiftUI
import Models
import ComposableArchitecture

public struct AddCurrencyView: View {
    let store: StoreOf<CurrencyRateReducer>
    @Environment(\.dismiss) private var dismiss
    
    @State private var code = ""
    @State private var symbol = ""
    @State private var name = ""
    @State private var usdRate = ""
    
    public init(store: StoreOf<CurrencyRateReducer>) {
        self.store = store
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Currency Information")) {
                    TextField("Code (e.g. GBP)", text: $code)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                    
                    TextField("Symbol (e.g. £)", text: $symbol)
                    
                    TextField("Name (e.g. British Pound)", text: $name)
                    
                    TextField("Exchange Rate to USD", text: $usdRate)
                        .keyboardType(.decimalPad)
                }
                
                Section {
                    Button("Save") {
                        saveCurrency()
                    }
                    .disabled(!isFormValid)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Add Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        store.send(.addCurrencyCancelled)
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !code.isEmpty && !symbol.isEmpty && !name.isEmpty && !usdRate.isEmpty && Double(usdRate) != nil
    }
    
    private func saveCurrency() {
        guard isFormValid, let rate = Double(usdRate) else { return }
        
        let newCurrency = Currency(
            code: code.uppercased(),
            symbol: symbol,
            name: name,
            usdRate: rate
        )
        
        Task {
            await store.send(.addCurrencySaved(newCurrency))
            dismiss()
        }
    }
}

#Preview {
    AddCurrencyView(
        store: Store(
            initialState: CurrencyRateReducer.State()
        ) {
            CurrencyRateReducer()
        }
    )
} 