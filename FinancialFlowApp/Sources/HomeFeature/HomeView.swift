// The Swift Programming Language
// https://docs.swift.org/swift-book

import AddDeviceFeature
import ComposableArchitecture
import SwiftUI
import AnalyticsFeature
import CurrencyRatesFeature

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
        ScrollView {
                VStack {
                    ForEach(self.store.state.devices, id: \.id) { device in
                        DeviceCardView(data: device)
                    }
                }
            }
    }

    public var body: some View {
        NavigationStack {
            devices
            .toolbar {
              ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                  store.send(.currencyRatesButtonTapped)
                } label: {
                  Image(systemName: "dollarsign.arrow.circlepath")
                }

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
            .sheet(
                item: self.$store.scope(state: \.destination?.currencyRate, action: \.destination.currencyRate)
            ) { store in
                CurrencyRateView(store: store)
            }
            .navigationTitle("Items \(self.store.count.map { $0.totalDailyCost.formatted(.currency(code: $0.currencyCode)) } ?? "")")
        }
    }
}
