// The Swift Programming Language
// https://docs.swift.org/swift-book

import AddDeviceFeature
import ComposableArchitecture
import SwiftUI
import AnalyticsFeature
import CurrencyRatesFeature
import SettingsFeature

public struct HomeView: View {
    @Bindable var store: StoreOf<HomeReducer>
    
    public init(store: StoreOf<HomeReducer>) {
        self.store = store
    }
    
    @ViewBuilder
    private var menu: some View {
        Menu {
            ForEach(HomeReducer.Ordering.allCases, id: \.self) { ordering in
                Button {
                    store.send(.onSortChanged(ordering))
                } label: {
                    Text(ordering.rawValue)
                }
            }
        } label: {
            Image(systemName: "line.horizontal.3.decrease.circle")
        }
    }

    @ViewBuilder
    private var devices: some View {
        List {
            ForEach(self.store.state.devices, id: \.id) { device in
                DeviceCardView(data: device)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            if let id = device.id {
                                store.send(.removeDevice(id))
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    public var body: some View {
      NavigationStack(path: self.$store.scope(state: \.path, action: \.path)) {
            devices
            .toolbar {
              ToolbarItemGroup(placement: .topBarLeading) {
                Button {
                  store.send(.settingsButtonTapped)
                } label: {
                  Image(systemName: "gear")
                }
              }
              
              ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                  store.send(.analyticsButtonTapped)
                } label: {
                  Image(systemName: "chart.bar.fill")
                }

                menu

                Button {
                  self.store.send(.addDeviceButtonTapped)
                } label: {
                  Image(systemName: "plus")
                }
              }
            }
            .sheet(
                item: self.$store.scope(state: \.destination?.addDevice, action: \.destination.addDevice)
            ) { store in
                NavigationStack {
                    AddDeviceView(store: store)
                }
                .presentationDetents([.medium])
            }
            .sheet(
                item: self.$store.scope(state: \.destination?.analytics, action: \.destination.analytics)
            ) { store in
                NavigationStack {
                    AnalyticsView(store: store)
                }
            }
            .navigationTitle("Items \(self.store.count.map { $0.totalDailyCost.formatted(.currency(code: $0.currencyCode)) } ?? "")")
      } destination: { store in
        switch store.case {
          case let .settings(store):
            SettingsView(store: store)
          case let .currencyRates(store):
            CurrencyRatesView(store: store)
        }
      }
    }
}
