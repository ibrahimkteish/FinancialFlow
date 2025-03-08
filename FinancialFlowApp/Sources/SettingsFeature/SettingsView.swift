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
                if let defaultCurrencyId = store.defaultCurrencyId {
                    HStack {
                        Text("Default Currency")
                        Spacer()
                        Text("USD") // TODO: Replace with actual currency code
                    }
                    
                    Button("Change Default Currency") {
                        // TODO: Add action to change default currency
                    }
                } else {
                    Button("Set Default Currency") {
                        // TODO: Add action to set default currency
                    }
                }
            } header: {
                Text("Currency")
            }
            
            Section {
                Button("Reset to Default Settings") {
                    store.send(.resetToDefaults)
                }
                .foregroundColor(.red)
            } header: {
                Text("Reset")
            } footer: {
                Text("This will reset all settings to their default values.")
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            store.send(.loadSettings)
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