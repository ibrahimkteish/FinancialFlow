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
      List {
        if store.currencies.isEmpty {
          // Only show loading if there are actually currencies in the database but they're not loaded yet
          if store.totalCurrenciesCount > 0 && store.searchTerm.isEmpty {
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
          } else if !store.searchTerm.isEmpty {
            // Show "no results" message if searching and nothing found
            Section {
              Text("No currencies match your search")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            }
          }
          // If totalCurrenciesCount is 0, don't show anything
        } else {
          Section(header: Text("Base Currency")) {
            if let usdCurrency = store.currencies.first(where: { $0.code == "USD" }) {
              currencyRow(usdCurrency)
            }
          }

          Section(header: Text("Other Currencies")) {
            ForEach(store.currencies.filter { $0.code != "USD" }, id: \.id) { currency in
              currencyRow(currency)
            }
          }
        }
      }
      .searchable(text: $store.searchTerm, prompt: "Search currencies")
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
                    get: { 
                        if let index = rateIndex {
                            return rates[index].1
                        } else {
                            // Use modern formatting with proper precision
                            return currency.usdRate.formatted(.number.precision(.fractionLength(0...4)))
                        }
                    },
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
