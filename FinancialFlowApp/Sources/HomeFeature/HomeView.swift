// The Swift Programming Language
// https://docs.swift.org/swift-book

import ComposableArchitecture
import SwiftUI

public struct HomeView: View {
    @Bindable var store: StoreOf<HomeReducer>
    
    public init(store: StoreOf<HomeReducer>) {
        self.store = store
    }
    
    public var body: some View {
        NavigationStack(path: self.$store.scope(state: \.path, action: \.path)) {
            ScrollView {
                VStack {
                    ForEach(self.store.state.devices, id: \.id) { device in
                        DeviceCardView(data: device)
                    }
                }
            }
            .toolbar {
              ToolbarItem(placement: .confirmationAction) {
                  Button {/* self.store.send(.addDevice)*/
                  } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationTitle("Items")
            
        } destination: { store in
            switch store.case {
                case let .addDevice(store):
                    AddDeviceView(store: store)
            }
        }
    }
}

public struct AddDeviceView: View {
    @Bindable var store: StoreOf<AddDeviceReducer>
    
    public init(store: StoreOf<AddDeviceReducer>) {
        self.store = store
    }
    
    public var body: some View {
        EmptyView()
    }
}
