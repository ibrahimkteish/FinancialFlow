// SettingsFeature.swift
// created by: @ibrahim koteish
// created at: 2025-03-8

import BuildClient
import ComposableArchitecture
import Models
import Foundation
import GRDB
import SharingGRDB
import UIApplicationClient
import UIKit

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

    public var presentation = SettingsPresentation(
        appTheme: .dark,
        notificationsEnabled: false,
        defaultCurrencyId: 0,
        defaultCurrency: .usd
      )
    public var isShowingCurrencyPicker = false
    
    public var appVersion: String = ""
    public var buildNumber: String = ""

    public init() {}
    
    mutating func updatePresentation(from settings: AppSettingsWithCurrency) {
      presentation.appTheme = AppTheme(rawValue: settings.settings.themeMode) ?? .system
      presentation.notificationsEnabled = settings.settings.notificationsEnabled
      presentation.defaultCurrencyId = settings.settings.defaultCurrencyId
      presentation.defaultCurrency = settings.defaultCurrency
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

    public var userInterfaceStyle: UIUserInterfaceStyle {
      switch self {
        case .dark:
          return .dark
        case .light:
          return .light
        case .system:
          return .unspecified
      }
    }
  }

  public enum Action: BindableAction, Equatable, Sendable {
    case binding(BindingAction<State>)
    case showCurrencyPicker
    case hideCurrencyPicker
    case setDefaultCurrency(Int64?)
    case openCurrencyRates
    case openLanguageSettings
    case onAppear
    case delegate(Delegate)
    case updatePresentation(AppSettingsWithCurrency)
    case updateVersionInfo(appVersion: String, buildNumber: String)
    
    @CasePathable
    public enum Delegate: Equatable, Sendable {
      case currencyRatesTapped
    }
  }

  @Dependency(\.build) var build
  @Dependency(\.defaultDatabase) var database
  @Dependency(\.applicationClient) var applicationClient

  public init() {}

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        case .binding(\.presentation):
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
            await applicationClient.setUserInterfaceStyle(appTheme.userInterfaceStyle)
          }

        case .binding:
          return .none

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

        case .openLanguageSettings:
          return .run { _ in
            // Open Settings app language section
            await applicationClient.openSettings()
          }

        case .onAppear:          
          return .run { [state] send in 
            // Get app version and build number and send them to the reducer
            let appVersion = build.buildVersion()
            let buildNumber = build.buildNumber()
            await send(.updateVersionInfo(appVersion: appVersion, buildNumber: buildNumber))
            
            for await newValue in state.$settingsWithCurrency.publisher.values {
              await send(.updatePresentation(newValue))
            }
          }

        case let .updatePresentation(newValue):
          state.updatePresentation(from: newValue)
          return .none

        case let .updateVersionInfo(appVersion, buildNumber):
          state.appVersion = appVersion
          state.buildNumber = buildNumber
          return .none
      }
    }
  }
}
