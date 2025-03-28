import ComposableArchitecture
import Generated
import Models
import SwiftUI

public struct SettingsView: View {
  @Bindable var store: StoreOf<SettingsFeature>

  public init(store: StoreOf<SettingsFeature>) {
    self.store = store
  }

  fileprivate func makeCell(with string: String) -> some View {
    HStack {
      Text(string)
      Spacer()
      Image(systemName: "network")
    }
    .contentShape(Rectangle())
  }

  public var body: some View {
    Form {
      Section {
        Picker(Strings.appTheme, selection: $store.presentation.appTheme) {
          ForEach(SettingsFeature.AppTheme.allCases, id: \.self) { theme in
            Text(theme.displayName)
              .tag(theme)
          }
        }
      } header: {
        Text(Strings.appearance)
      } footer: {
        Text(Strings.themeFooter)
      }

      Section {
        if let currency = store.presentation.defaultCurrency {
          HStack {
            Text(Strings.defaultCurrency)
            Spacer()
            Text("\(currency.code) (\(currency.symbol))")
              .foregroundColor(.secondary)
          }

          Button(Strings.changeDefaultCurrency) {
            store.send(.showCurrencyPicker)
          }
        } else {
          Button(Strings.setDefaultCurrency) {
            store.send(.showCurrencyPicker)
          }
        }

        Button(Strings.viewCurrencyRates) {
          store.send(.openCurrencyRates)
        }
      } header: {
        Text(Strings.currency)
      }

      Section {
        Button {
          store.send(.openLanguageSettings)
        } label: {
          HStack {
            Text(Strings.language)
            Spacer()
            Image(systemName: "chevron.right")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
      } header: {
        Text(Strings.languageRegion)
      } footer: {
        Text(Strings.opensSettings)
      }

      Section(Strings.acknowledgements) {
        ForEach(self.store.acknowledgements) { acknowledgement in
          Link(
            destination: acknowledgement.url,
            label: {
              self.makeCell(with: acknowledgement.name)
            }
          )
        }
      }

      Section(Strings.legal) {
        ForEach(["https://www.termsfeed.com/live/3d38411a-f533-4e2d-999d-e83d8eb2fe1b"], id: \.self) { url in
          Link(destination: URL(string: url)!) {
            Text(Strings.termsAndConditions)
          }
        }
      }

      Section {
        HStack {
          Text(Strings.version)
          Spacer()
          Text("\(store.appVersion) (\(store.buildNumber))")
            .foregroundColor(.secondary)
        }
      } header: {
        Text(Strings.about)
      }
    }
    .task {
      await store.send(.onAppear).finish()
    }
    .navigationTitle(Strings.settings)

    .sheet(isPresented: $store.isShowingCurrencyPicker) {
      NavigationStack {
        CurrencyPickerView(
          currencies: store.availableCurrencies,
          selectedCurrencyId: store.presentation.defaultCurrencyId,
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
    .navigationTitle(Strings.selectCurrency)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button(Strings.cancel) {
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
        initialState: SettingsFeature.State()
      ) {
        SettingsFeature()
      }
    )
  }
}
