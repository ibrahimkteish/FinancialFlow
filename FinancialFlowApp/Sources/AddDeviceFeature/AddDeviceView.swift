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
                TextField("Device Name", text: $store.deviceName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if store.currencies.isEmpty {
                    HStack {
                        Text("Loading currencies...")
                        Spacer()
                        ProgressView()
                    }
                } else {
                    Picker("Currency", selection: $store.selectedCurrencyId) {
                        ForEach(store.currencies, id: \.id) { currency in
                            Text("\(currency.code) (\(currency.symbol)) - \(currency.name)")
                                .tag(currency.id!)
                        }
                    }
                }
                
                HStack {
                    Text("Purchase Price")
                    Spacer()
                    TextField("0.00", text: $store.purchasePrice)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                
                DatePicker(
                    "Purchase Date",
                    selection: $store.purchaseDate,
                    displayedComponents: .date
                )
            } header: {
                Text("Device Information")
            }

            Section  {
                HStack {
                    Text("Rate")
                    Spacer()
                    TextField("0.00", text: $store.usageRate)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                
                Picker("Period", selection: $store.selectedUsageRatePeriodId) {
                    ForEach(store.usageRatePeriods, id: \.id) { period in
                        Text("Per \(period.name.capitalized)")
                            .tag(period.id!)
                    }
                }
            } header: {
                Text("Usage Rate")
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Submit") {
                    self.store.send(.submitButtonTapped)
                }
                .disabled(!store.isValid)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    self.store.send(.cancelButtonTapped)
                }
            }
        }
        .navigationTitle("Add New Device")
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
