import SwiftUI
import ComposableArchitecture
import Models

public struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsReducer>
    
    public init(store: StoreOf<SettingsReducer>) {
        self.store = store
    }
    
    public var body: some View {
        Form {
            Section {
              Picker("App Theme", selection: $store.appTheme) {
                    ForEach(SettingsReducer.AppTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName)
                            .tag(theme)
                    }
                }
                
                Toggle("Enable Notifications", isOn: $store.notificationsEnabled)
            } header: {
                Text("Appearance")
            } footer: {
                Text("Theme changes will affect the app's appearance.")
            }
            
            Section {
                if let currency = store.defaultCurrency {
                    HStack {
                        Text("Default Currency")
                        Spacer()
                        Text("\(currency.code) (\(currency.symbol))")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Change Default Currency") {
                        store.send(.showCurrencyPicker)
                    }
                } else {
                    Button("Set Default Currency") {
                        store.send(.showCurrencyPicker)
                    }
                }
                
                Button("View Currency Rates") {
                    store.send(.openCurrencyRates)
                }
            } header: {
                Text("Currency")
            }
        }
        .navigationTitle("Settings")
    
        .sheet(isPresented: $store.isShowingCurrencyPicker) {
            NavigationStack {
                CurrencyPickerView(
                    currencies: store.availableCurrencies,
                    selectedCurrencyId: store.defaultCurrencyId,
                    onSelect: { currencyId in
                        store.send(.setDefaultCurrency(currencyId))
                    },
                    onCancel: {
                        store.send(.hideCurrencyPicker)
                    }
                )
            }
        }
    }
}

// Currency picker view for selecting default currency
struct CurrencyPickerView: View {
    let currencies: [Currency]
    let selectedCurrencyId: Int64?
    let onSelect: (Int64?) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        List {
            Button {
                onSelect(nil)
            } label: {
                HStack {
                    Text("None")
                    Spacer()
                    if selectedCurrencyId == nil {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            ForEach(currencies, id: \.id) { currency in
                Button {
                    onSelect(currency.id)
                } label: {
                    HStack {
                        Text("\(currency.code) (\(currency.symbol)) - \(currency.name)")
                        Spacer()
                        if selectedCurrencyId == currency.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Currency")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    onCancel()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(
            store: Store(
                initialState: SettingsReducer.State()
            ) {
                SettingsReducer()
            }
        )
    }
} 
