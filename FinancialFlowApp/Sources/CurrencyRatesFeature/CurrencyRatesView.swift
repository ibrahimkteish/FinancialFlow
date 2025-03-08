import SwiftUI
import Models
import ComposableArchitecture
import SharingGRDB

public struct CurrencyRatesView: View {
    @Bindable var store: StoreOf<CurrencyRatesReducer>
    @Environment(\.dismiss) private var dismiss
    @State private var rates: [(Currency, String)] = []
    
    public init(store: StoreOf<CurrencyRatesReducer>) {
        self.store = store
    }
    
    public var body: some View {
        VStack {
            if #available(iOS 17.0, *) {
                List {
                    if store.currencies.isEmpty {
                        Section {
                            HStack {
                                Spacer()
                                VStack {
                                    Text("Loading currencies...")
                                        .foregroundColor(.secondary)
                                    ProgressView()
                                        .padding()
                                }
                                Spacer()
                            }
                        }
                    } else {
                        Section(header: Text("Base Currency")) {
                            if let usdCurrency = store.currencies.first(where: { $0.code == "USD" }) {
                                currencyRow(usdCurrency)
                            }
                        }
                        
                        Section(header: Text("Other Currencies")) {
                            if filteredCurrencies.filter({ $0.code != "USD" }).isEmpty && !store.searchTerm.isEmpty {
                                Text("No currencies match your search")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                ForEach(filteredCurrencies.filter { $0.code != "USD" }, id: \.id) { currency in
                                    currencyRow(currency)
                                }
                            }
                        }
                    }
                }
                .searchable(text: $store.searchTerm, prompt: "Search currencies")
            } else {
                // Fallback for iOS 16 and earlier
                // Simple search field for iOS 16 and earlier
                TextField("Search currencies", text: $store.searchTerm)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                List {
                    if store.currencies.isEmpty {
                        Section {
                            HStack {
                                Spacer()
                                VStack {
                                    Text("Loading currencies...")
                                        .foregroundColor(.secondary)
                                    ProgressView()
                                        .padding()
                                }
                                Spacer()
                            }
                        }
                    } else {
                        if let usdCurrency = store.currencies.first(where: { $0.code == "USD" }) {
                            Section(header: Text("Base Currency")) {
                                currencyRow(usdCurrency)
                            }
                        }
                        
                        Section(header: Text("Other Currencies")) {
                            if filteredCurrencies.filter({ $0.code != "USD" }).isEmpty && !store.searchTerm.isEmpty {
                                Text("No currencies match your search")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                ForEach(filteredCurrencies.filter { $0.code != "USD" }, id: \.id) { currency in
                                    currencyRow(currency)
                                }
                            }
                        }
                    }
                }
            }
        }
        .sheet(
          isPresented: $store.showingAddCurrency
        ) {
          AddCurrencyView(store: store)
        }
        .onAppear {
          store.send(.fetchCurrencyRates)
        }
        .navigationTitle("Currency Rates")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let updatedCurrencies = store.currencies.map { currency in
                        if let rateIndex = rates.firstIndex(where: { $0.0.id == currency.id }),
                           let newRate = Double(rates[rateIndex].1) {
                            var updatedCurrency = currency
                            updatedCurrency.usdRate = newRate
                            return updatedCurrency
                        }
                        return currency
                    }
                        store.send(.updateCurrencyRates(updatedCurrencies))
                }
            }
            
            // Add a button to add new currencies
            ToolbarItem(placement: .primaryAction) {
                Button {
                    store.send(.addCurrencyButtonTapped)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    @ViewBuilder
    private func currencyRow(_ currency: Currency) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(currency.symbol)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(currency.name)
                        .font(.headline)
                }
                Text(currency.code)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if currency.code == "USD" {
                Text("Base")
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
            } else {
                let rateIndex = rates.firstIndex(where: { $0.0.id == currency.id })
                TextField("Rate", text: Binding(
                    get: { rateIndex.map { rates[$0].1 } ?? String(format: "%.4f", currency.usdRate) },
                    set: { newValue in
                        if let index = rateIndex {
                            rates[index].1 = newValue
                        } else {
                            rates.append((currency, newValue))
                        }
                    }
                ))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if currency.code != "USD" { // Don't allow deleting the base currency
                Button(role: .destructive) {
                    if let id = currency.id {
                        store.send(.deleteCurrency(id))
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

#Preview {
    CurrencyRatesView(
        store: Store(
            initialState: CurrencyRatesReducer.State()
        ) {
            CurrencyRatesReducer()
        }
    )
} 
