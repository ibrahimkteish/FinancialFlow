import Generated
import SwiftUI
import ComposableArchitecture
import Models
public struct AddDeviceView: View {
    @Bindable var store: StoreOf<AddDeviceReducer>
    
    public init(store: StoreOf<AddDeviceReducer>) {
        self.store = store
    }
    
    public var body: some View {
        Form {
            Section {
                TextField(Strings.deviceName, text: $store.deviceName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if store.currencies.isEmpty {
                    HStack {
                        Text(Strings.loadingCurrencies)
                        Spacer()
                        ProgressView()
                    }
                } else {
                    Picker(Strings.currency, selection: $store.selectedCurrencyId) {
                        ForEach(store.currencies, id: \.id) { currency in
                            Text("\(currency.code) (\(currency.symbol)) - \(currency.name)")
                                .tag(currency.id!)
                        }
                    }
                }
                
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
            } header: {
                Text(Strings.deviceInformation)
            }

            Section  {
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
            } header: {
                Text(Strings.usageRate)
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
                initialState: AddDeviceReducer.State()
            ) {
                AddDeviceReducer()
            }
        )
    }
}
