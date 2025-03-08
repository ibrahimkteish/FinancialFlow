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

    public var presentation: SettingsPresentation
    public var isShowingCurrencyPicker = false

    public init(settingsWithCurrency: AppSettingsWithCurrency) {
      self._settingsWithCurrency = SharedReader.init(wrappedValue: settingsWithCurrency, .fetch(SettingsFetcher(), animation: .default))
      self.presentation = SettingsPresentation(
        appTheme: .dark,
        notificationsEnabled: false,
        defaultCurrencyId: 0,
        defaultCurrency: .usd
      )
    }
  }

  public struct SettingsPresentation: Equatable, Sendable {
    public var appTheme: AppTheme
    public var notificationsEnabled: Bool
    public var defaultCurrencyId: Int64?
    public var defaultCurrency: Currency?
    
    public init(
      appTheme: AppTheme,
      notificationsEnabled: Bool,
      defaultCurrencyId: Int64?,
      defaultCurrency: Currency?
    ) {
      self.appTheme = appTheme
      self.notificationsEnabled = notificationsEnabled
      self.defaultCurrencyId = defaultCurrencyId
      self.defaultCurrency = defaultCurrency
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
    case showCurrencyPicker
    case hideCurrencyPicker
    case setDefaultCurrency(Int64?)
    case openCurrencyRates
    case onAppear
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
          let appTheme = state.presentation.appTheme
          let notificationsEnabled = state.presentation.notificationsEnabled
          let defaultCurrencyId = state.presentation.defaultCurrencyId
          let settings = AppSettings(
            id: state.settingsWithCurrency.settings.id,
            themeMode: appTheme.rawValue,
            defaultCurrencyId: defaultCurrencyId,
            notificationsEnabled: notificationsEnabled
          )
          
          return .run { _ in
            try await database.write { db in
              // Update the settings in database
              try settings.update(db)
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

        case .onAppear:
          state.presentation.appTheme = AppTheme(rawValue: state.settingsWithCurrency.settings.themeMode) ?? .system
          state.presentation.notificationsEnabled = state.settingsWithCurrency.settings.notificationsEnabled
          state.presentation.defaultCurrencyId = state.settingsWithCurrency.settings.defaultCurrencyId
          state.presentation.defaultCurrency = state.settingsWithCurrency.defaultCurrency
          return .none

        case .openCurrencyRates:
          return .send(.delegate(.currencyRatesTapped))
      }
    }
  }
}
