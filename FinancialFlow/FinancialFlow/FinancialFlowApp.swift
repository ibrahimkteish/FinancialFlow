//
//  FinancialFlowApp.swift
//  FinancialFlow
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
struct FinancialFlowApp: App {

    static let store: StoreOf<HomeReducer> = .init(initialState: .init(), reducer: { HomeReducer() })
    
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
