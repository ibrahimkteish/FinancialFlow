import ComposableArchitecture
import Generated
import Models
import SwiftUI
public struct AddDeviceView: View {
  @Bindable var store: StoreOf<AddDeviceFeature>

  public init(store: StoreOf<AddDeviceFeature>) {
    self.store = store
  }

  public var body: some View {
    Form {
      // Currency Section - First input
      Section(header: Text(Strings.currency)) {
        if store.currencies.isEmpty {
          HStack {
            Text(Strings.loadingCurrencies)
            Spacer()
            Button {
              store.send(.addCurrencyTapped)
            } label: {
              Text("Add Currency")
                .foregroundColor(.accentColor)
            }
          }
        } else {
          Picker(Strings.currency, selection: $store.selectedCurrencyId) {
            ForEach(store.currencies, id: \.id) { currency in
              Text("\(currency.code) (\(currency.symbol)) - \(currency.name)")
                .tag(currency.id!)
            }
          }
          .pickerStyle(.navigationLink)
          
          Button {
            store.send(.addCurrencyTapped)
          } label: {
            HStack {
              Image(systemName: "plus.circle")
              Text("Add New Currency")
            }
            .font(.footnote)
            .foregroundColor(.accentColor)
          }
        }
      }
      
      // Device Information Section
      Section(header: Text(Strings.deviceInformation)) {
        TextField(Strings.deviceName, text: $store.deviceName)
          .textFieldStyle(RoundedBorderTextFieldStyle())

        HStack {
          Text(Strings.purchasePrice)
          Spacer()
          TextField("0.00", text: $store.purchasePrice)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
        }

        DatePicker(
          Strings.purchaseDate,
          selection: $store.purchaseDate,
          displayedComponents: .date
        )
      }

      // Usage Rate Section
      Section(header: Text(Strings.usageRate)) {
        HStack {
          Text(Strings.justRate)
          Spacer()
          TextField("0.00", text: $store.usageRate)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
        }

        Picker(Strings.period, selection: $store.selectedUsageRatePeriodId) {
          ForEach(store.usageRatePeriods, id: \.id) { period in
            Text(Strings.perPeriod(period.localizedName.capitalized))
              .tag(period.id!)
          }
        }
      }
    }
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button(Strings.submit) {
          self.store.send(.submitButtonTapped)
        }
        .disabled(!store.isValid)
      }
      ToolbarItem(placement: .cancellationAction) {
        Button(Strings.cancel) {
          self.store.send(.cancelButtonTapped)
        }
      }
    }
    .navigationTitle(Strings.addNewDevice)
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  NavigationStack {
    AddDeviceView(
      store: Store(
        initialState: AddDeviceFeature.State()
      ) {
        AddDeviceFeature()
      }
    )
  }
}
