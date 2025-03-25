//
//  DeviceValueApp.swift
//  DeviceValue
//
//  Created by Ibrahim Koteish on 15/2/25.
//

import ComposableArchitecture
import Dependencies
import HomeFeature
import Models
import SharingGRDB
import SwiftUI

@main
struct DeviceValueApp: App {

    static let store: StoreOf<HomeFeature> = .init(initialState: .init(), reducer: { HomeFeature() })
    
    init() {
        prepareDependencies {
            $0.defaultDatabase = .appDatabase
        }
    }
    
    var body: some Scene {
        WindowGroup {
            VStack {
                HomeView(store: Self.store)
            }
        }
    }
}
