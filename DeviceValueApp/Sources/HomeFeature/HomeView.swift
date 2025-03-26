// The Swift Programming Language
// https://docs.swift.org/swift-book

import AddDeviceFeature
import AnalyticsFeature
import ComposableArchitecture
import CurrencyRatesFeature
import Generated
import SettingsFeature
import SwiftUI

public struct HomeView: View {
  @Bindable var store: StoreOf<HomeFeature>

  public init(store: StoreOf<HomeFeature>) {
    self.store = store
  }

  @ViewBuilder
  private var menu: some View {
    Menu {
      ForEach(HomeFeature.Ordering.allCases, id: \.self) { ordering in
        Button {
          store.send(.onSortChanged(ordering))
        } label: {
          Text(ordering.localizedName)
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
              Label(Strings.delete, systemImage: "trash")
            }
            Button {
              store.send(.editDeviceTapped(device.device))
            } label: {
              Label(Strings.edit, systemImage: "pencil")
            }
            .tint(.accentColor)

            Button {
              store.send(.cloneDeviceTapped(device.device))
            } label: {
              Label(Strings.clone, systemImage: "doc.on.doc")
            }
            .tint(.orange)
          }
      }
      .listRowBackground(Color.clear)
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
  }

  @ViewBuilder
  private var floatingAddButton: some View {
    Button {
      self.store.send(.addDeviceButtonTapped)
    } label: {
      Image(systemName: "plus")
        .font(.title2)
        .fontWeight(.semibold)
        .foregroundColor(.white)
        .frame(width: 56, height: 56)
        .background(
          Circle()
            .fill(Color.accentColor)
            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
        )
    }
    .padding(.trailing, 20)
    .padding(.bottom, 20)
  }

  private var devicesView: some View {
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
        }
      }
      .onAppear {
        store.send(.onAppear)
      }
  }

  public var body: some View {
    NavigationStack(path: self.$store.scope(state: \.path, action: \.path)) {
      ZStack(alignment: .bottomTrailing) {
        devicesView
        floatingAddButton
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
        item: self.$store.scope(state: \.destination?.addCurrency, action: \.destination.addCurrency)
      ) { store in
        NavigationStack {
          AddCurrencyView(store: store)
        }
      }
      .navigationTitle(self.store.count.map {
        Strings.itemsWithCost($0.totalDailyCost.formatted(.currency(code: $0.currencyCode)))
      } ?? "")
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
