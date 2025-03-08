import SwiftUI
import Models
import ComposableArchitecture
import SharingGRDB

public struct CurrencyRatesView: View {
    let store: StoreOf<CurrencyRateReducer>
    @Environment(\.dismiss) private var dismiss
    @State private var rates: [(Currency, String)] = []
    @State private var searchText = ""
    
    public init(store: StoreOf<CurrencyRateReducer>) {
        self.store = store
    }
    
    var filteredCurrencies: [Currency] {
        if searchText.isEmpty {
            return store.currencies
        } else {
            return store.currencies.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) || 
                $0.code.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    public var body: some View {
        Group {
            if store.currencies.isEmpty {
                VStack {
                    Text("Loading currencies...")
                        .foregroundColor(.secondary)
                    ProgressView()
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack {
                    if #available(iOS 17.0, *) {
                        List {
                            Section(header: Text("Base Currency")) {
                                if let usdCurrency = store.currencies.first(where: { $0.code == "USD" }) {
                                    currencyRow(usdCurrency)
                                }
                            }
                            
                            Section(header: Text("Other Currencies")) {
                                ForEach(filteredCurrencies.filter { $0.code != "USD" }, id: \.id) { currency in
                                    currencyRow(currency)
                                }
                            }
                        }
                        .searchable(text: $searchText, prompt: "Search currencies")
                    } else {
                        // Fallback for iOS 16 and earlier
                        List {
                            if let usdCurrency = store.currencies.first(where: { $0.code == "USD" }) {
                                Section(header: Text("Base Currency")) {
                                    currencyRow(usdCurrency)
                                }
                            }
                            
                            Section(header: Text("Other Currencies")) {
                                ForEach(filteredCurrencies.filter { $0.code != "USD" }, id: \.id) { currency in
                                    currencyRow(currency)
                                }
                            }
                        }
                        
                        // Simple search field for iOS 16 and earlier
                        TextField("Search currencies", text: $searchText)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                }
            }
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
                    Task {
                        await store.send(.updateCurrencyRates(updatedCurrencies))
                        dismiss()
                    }
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
        .task {
            await store.send(.fetchCurrencyRates)
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
            initialState: CurrencyRateReducer.State()
        ) {
            CurrencyRateReducer()
        }
    )
} 