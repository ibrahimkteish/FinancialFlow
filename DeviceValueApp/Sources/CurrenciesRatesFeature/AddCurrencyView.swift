import ComposableArchitecture
import Generated
import Models
import SwiftUI

public struct AddCurrencyView: View {
  let store: StoreOf<CurrenciesRatesFeature>
  @Environment(\.dismiss) private var dismiss

  @State private var code = ""
  @State private var symbol = ""
  @State private var name = ""
  @State private var usdRate = ""

  public init(store: StoreOf<CurrenciesRatesFeature>) {
    self.store = store
  }

  public var body: some View {
    NavigationStack {
      Form {
        Section(
          header: Text(Strings.currencyInformation),
          footer: Text(Strings.enterOneUSDExplanation)
            .font(.caption)
        ) {
          TextField(Strings.codeExample, text: $code)
            .autocapitalization(.allCharacters)
            .disableAutocorrection(true)

          TextField(Strings.currencySymbol, text: $symbol)

          TextField(Strings.nameOfCurrency, text: $name)

          VStack(alignment: .leading, spacing: 4) {
            TextField(Strings.exchangeRateToUSD, text: $usdRate)
              .keyboardType(.decimalPad)

            Text(Strings.equalsOneUSD)
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }

        Section {
          Button(Strings.save) {
            saveCurrency()
          }
          .disabled(!isFormValid)
          .frame(maxWidth: .infinity)
        }
      }
      .navigationTitle(Strings.addCurrency)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(Strings.cancel) {
            store.send(.addCurrencyCancelled)
            dismiss()
          }
        }
      }
    }
  }

  private var isFormValid: Bool {
    !self.code.isEmpty && !self.symbol.isEmpty && !self.name.isEmpty && !self.usdRate
      .isEmpty && Double(self.usdRate) != nil
  }

  private func saveCurrency() {
    guard self.isFormValid, let rate = Double(usdRate) else { return }

    let newCurrency = Currency(
      code: code.uppercased(),
      symbol: self.symbol,
      name: self.name,
      usdRate: rate
    )

    self.store.send(.addCurrencySaved(newCurrency))
  }
}

#Preview {
  AddCurrencyView(
    store: Store(
      initialState: CurrenciesRatesFeature.State()
    ) {
      CurrenciesRatesFeature()
    }
  )
}
