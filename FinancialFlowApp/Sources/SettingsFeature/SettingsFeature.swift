// SettingsFeature.swift
// created by: @ibrahim koteish
// created at: 2025-03-8

import ComposableArchitecture
import Models
import Foundation
import GRDB
import SharingGRDB

@Reducer
public struct SettingsReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        // App settings state
        public var appTheme: AppTheme
        public var notificationsEnabled: Bool
        public var defaultCurrencyId: Int64?
        
        public init(
            appTheme: AppTheme = .system,
            notificationsEnabled: Bool = true,
            defaultCurrencyId: Int64? = nil
        ) {
            self.appTheme = appTheme
            self.notificationsEnabled = notificationsEnabled
            self.defaultCurrencyId = defaultCurrencyId
        }
    }
    
    public enum AppTheme: String, CaseIterable, Equatable, Sendable {
        case light
        case dark
        case system
        
        public var displayName: String {
            switch self {
            case .light: return "Light"
            case .dark: return "Dark"
            case .system: return "System"
            }
        }
    }

    public enum Action: BindableAction, Equatable, Sendable {
        case binding(BindingAction<State>)
        case saveSettings
        case loadSettings
        case resetToDefaults
    }

    @Dependency(\.defaultDatabase) var database

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .saveSettings:
                // TODO: Implement saving settings to database or UserDefaults
                return .none
                
            case .loadSettings:
                // TODO: Implement loading settings from database or UserDefaults
                return .none
                
            case .resetToDefaults:
                state.appTheme = .system
                state.notificationsEnabled = true
                state.defaultCurrencyId = nil
                return .run { send in
                    await send(.saveSettings)
                }
            }
        }
    }
} 