// SettingsFeature.swift
// created by: @ibrahim koteish
// created at: 2025-03-8

import ComposableArchitecture
import Models
import Foundation
import GRDB
import SharingGRDB

// A struct to hold settings with optional default currency
public struct AppSettingsWithCurrency: Equatable, Sendable {
    public var settings: AppSettings
    public var defaultCurrency: Currency?
    
    public init(settings: AppSettings = .init(), defaultCurrency: Currency? = nil) {
        self.settings = settings
        self.defaultCurrency = defaultCurrency
    }
}

@Reducer
public struct SettingsReducer: Sendable {
  // Define a FetchKeyRequest for settings
  public struct SettingsFetcher: FetchKeyRequest {
    public typealias State = AppSettingsWithCurrency

    public init() {}

    public func fetch(_ db: Database) throws -> AppSettingsWithCurrency {
      print("Fetching app settings from database")

      // Get settings with optional currency
      let settings = try AppSettings
        .including(optional: AppSettings.defaultCurrency)
        .fetchOne(db) ?? AppSettings()

      // Get the associated currency if there's a defaultCurrencyId
      var currency: Currency? = nil
      if let currencyId = settings.defaultCurrencyId {
        currency = try Currency.fetchOne(db, key: currencyId)
      }

      return AppSettingsWithCurrency(settings: settings, defaultCurrency: currency)
    }
  }

  @ObservableState
  public struct State: Equatable, Sendable {
    @SharedReader(.fetch(SettingsFetcher()))
    public var settingsWithCurrency: AppSettingsWithCurrency = .init()

    @SharedReader(.fetchAll(sql: "SELECT * from currencies ORDER BY code = 'USD' DESC, name", animation: .default))
    public var availableCurrencies: [Currency]

    public var appTheme: AppTheme {
      get { 
        AppTheme(rawValue: settingsWithCurrency.settings.themeMode) ?? .system
      }
      set {
        var settings = settingsWithCurrency.settings
        settings.themeMode = newValue.rawValue
        settingsWithCurrency.settings = settings
      }
    }

    public var notificationsEnabled: Bool {
      get { settingsWithCurrency.settings.notificationsEnabled }
      set {
        var settings = settingsWithCurrency.settings
        settings.notificationsEnabled = newValue
        settingsWithCurrency.settings = settings
      }
    }

    public var defaultCurrencyId: Int64? {
      get { settingsWithCurrency.settings.defaultCurrencyId }
    }


    public var isShowingCurrencyPicker = false

    public init() {}
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
    case showCurrencyPicker
    case hideCurrencyPicker
    case setDefaultCurrency(Int64?)
    case openCurrencyRates
    case delegate(Delegate)

    @CasePathable
    public enum Delegate: Equatable, Sendable {
      case currencyRatesTapped
    }
  }

  @Dependency(\.defaultDatabase) var database

  public init() {}

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        case .binding:
          let settings = state.settingsWithCurrency.settings
          return .run { _ in
            try await database.write { db in
              // Update the settings in database
              var settingsToUpdate = settings
              settingsToUpdate.updatedAt = Date()
              try settingsToUpdate.update(db)
            }
          }

        case .delegate:
          return .none

        case .showCurrencyPicker:
          state.isShowingCurrencyPicker = true
          return .none

        case .hideCurrencyPicker:
          state.isShowingCurrencyPicker = false
          return .none

        case let .setDefaultCurrency(currencyId):
          // Update default currency
          var updatedSettings = state.settingsWithCurrency.settings
          updatedSettings.defaultCurrencyId = currencyId
          updatedSettings.updatedAt = Date()

          return .run { [updatedSettings] send in
            try await database.write { db in
              // Update the settings in database
              try updatedSettings.update(db)
            }
            // Hide currency picker after database update
            await send(.hideCurrencyPicker)
          }

        case .openCurrencyRates:
          return .send(.delegate(.currencyRatesTapped))
      }
    }
  }
}
