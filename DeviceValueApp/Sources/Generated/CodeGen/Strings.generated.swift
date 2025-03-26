// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum Strings {
  /// About
  public static let about = Strings.tr("Localizable", "About", fallback: "About")
  /// Acknowledgements
  public static let acknowledgements = Strings.tr("Localizable", "Acknowledgements", fallback: "Acknowledgements")
  /// Acknowledgements
  public static let acknowledgementsDescription = Strings.tr("Localizable", "AcknowledgementsDescription", fallback: "Acknowledgements")
  /// Add Currency
  public static let addCurrency = Strings.tr("Localizable", "AddCurrency", fallback: "Add Currency")
  /// Add New Device
  public static let addNewDevice = Strings.tr("Localizable", "AddNewDevice", fallback: "Add New Device")
  /// Appearance
  public static let appearance = Strings.tr("Localizable", "Appearance", fallback: "Appearance")
  /// App Theme
  public static let appTheme = Strings.tr("Localizable", "AppTheme", fallback: "App Theme")
  /// Base
  public static let base = Strings.tr("Localizable", "Base", fallback: "Base")
  /// Base Currency
  public static let baseCurrency = Strings.tr("Localizable", "BaseCurrency", fallback: "Base Currency")
  /// Cancel
  public static let cancel = Strings.tr("Localizable", "Cancel", fallback: "Cancel")
  /// Change Default Currency
  public static let changeDefaultCurrency = Strings.tr("Localizable", "ChangeDefaultCurrency", fallback: "Change Default Currency")
  /// Code (e.g. GBP)
  public static let codeExample = Strings.tr("Localizable", "CodeExample", fallback: "Code (e.g. GBP)")
  /// Consumed Value
  public static let consumedValue = Strings.tr("Localizable", "ConsumedValue", fallback: "Consumed Value")
  /// Created At
  public static let createdAt = Strings.tr("Localizable", "CreatedAt", fallback: "Created At")
  /// Currency
  public static let currency = Strings.tr("Localizable", "Currency", fallback: "Currency")
  /// Currency Information
  public static let currencyInformation = Strings.tr("Localizable", "CurrencyInformation", fallback: "Currency Information")
  /// Currency Rates
  public static let currencyRates = Strings.tr("Localizable", "CurrencyRates", fallback: "Currency Rates")
  /// Symbol (e.g. £)
  public static let currencySymbol = Strings.tr("Localizable", "CurrencySymbol", fallback: "Symbol (e.g. £)")
  /// Daily Rate: %@
  public static func dailyRate(_ p1: Any) -> String {
    return Strings.tr("Localizable", "DailyRate", String(describing: p1), fallback: "Daily Rate: %@")
  }
  /// Daily Usage
  public static let dailyUsage = Strings.tr("Localizable", "DailyUsage", fallback: "Daily Usage")
  /// day
  public static let day = Strings.tr("Localizable", "day", fallback: "day")
  /// days
  public static let days = Strings.tr("Localizable", "days", fallback: "days")
  /// Days Left: %lld
  public static func daysLeft(_ p1: Int) -> String {
    return Strings.tr("Localizable", "DaysLeft", p1, fallback: "Days Left: %lld")
  }
  /// Default Currency
  public static let defaultCurrency = Strings.tr("Localizable", "DefaultCurrency", fallback: "Default Currency")
  /// Delete
  public static let delete = Strings.tr("Localizable", "Delete", fallback: "Delete")
  /// Device Information
  public static let deviceInformation = Strings.tr("Localizable", "DeviceInformation", fallback: "Device Information")
  /// Device Name
  public static let deviceName = Strings.tr("Localizable", "DeviceName", fallback: "Device Name")
  /// Device Usage
  public static let deviceUsage = Strings.tr("Localizable", "DeviceUsage", fallback: "Device Usage")
  /// Edit
  public static let edit = Strings.tr("Localizable", "Edit", fallback: "Edit")
  /// Enter the direct exchange rate: how many units of this currency equal exactly 1 USD. Exchange rates vary over time, so enter the current market value.
  public static let enterOneUSDExplanation = Strings.tr("Localizable", "EnterOneUSDExplanation", fallback: "Enter the direct exchange rate: how many units of this currency equal exactly 1 USD. Exchange rates vary over time, so enter the current market value.")
  /// Enter how many units of this currency equals 1 USD
  public static let equalsOneUSD = Strings.tr("Localizable", "EqualsOneUSD", fallback: "Enter how many units of this currency equals 1 USD")
  /// Exchange Rate to USD
  public static let exchangeRateToUSD = Strings.tr("Localizable", "ExchangeRateToUSD", fallback: "Exchange Rate to USD")
  /// Expected: %lld%%
  public static func expected(_ p1: Int) -> String {
    return Strings.tr("Localizable", "Expected", p1, fallback: "Expected: %lld%%")
  }
  /// Items %@
  public static func itemsWithCost(_ p1: Any) -> String {
    return Strings.tr("Localizable", "ItemsWithCost", String(describing: p1), fallback: "Items %@")
  }
  /// Rate
  public static let justRate = Strings.tr("Localizable", "JustRate", fallback: "Rate")
  /// Language
  public static let language = Strings.tr("Localizable", "Language", fallback: "Language")
  /// Language & Region
  public static let languageRegion = Strings.tr("Localizable", "LanguageRegion", fallback: "Language & Region")
  /// Legal
  public static let legal = Strings.tr("Localizable", "Legal", fallback: "Legal")
  /// Loading currencies...
  public static let loadingCurrencies = Strings.tr("Localizable", "LoadingCurrencies", fallback: "Loading currencies...")
  /// month
  public static let month = Strings.tr("Localizable", "month", fallback: "month")
  /// Name
  public static let name = Strings.tr("Localizable", "Name", fallback: "Name")
  /// Name (e.g. British Pound)
  public static let nameOfCurrency = Strings.tr("Localizable", "NameOfCurrency", fallback: "Name (e.g. British Pound)")
  /// No currencies match your search
  public static let noCurrencyFound = Strings.tr("Localizable", "NoCurrencyFound", fallback: "No currencies match your search")
  /// None
  public static let `none` = Strings.tr("Localizable", "None", fallback: "None")
  /// Opens system settings to change app language.
  public static let opensSettings = Strings.tr("Localizable", "OpensSettings", fallback: "Opens system settings to change app language.")
  /// Other Currencies
  public static let otherCurrencies = Strings.tr("Localizable", "OtherCurrencies", fallback: "Other Currencies")
  /// %lld%% used
  public static func percentUsed(_ p1: Int) -> String {
    return Strings.tr("Localizable", "PercentUsed", p1, fallback: "%lld%% used")
  }
  /// Period
  public static let period = Strings.tr("Localizable", "Period", fallback: "Period")
  /// Per %@
  public static func perPeriod(_ p1: Any) -> String {
    return Strings.tr("Localizable", "PerPeriod", String(describing: p1), fallback: "Per %@")
  }
  /// Purchase Date
  public static let purchaseDate = Strings.tr("Localizable", "PurchaseDate", fallback: "Purchase Date")
  /// Purchased for %@
  public static func purchasedFor(_ p1: Any) -> String {
    return Strings.tr("Localizable", "PurchasedFor", String(describing: p1), fallback: "Purchased for %@")
  }
  /// Purchase Price
  public static let purchasePrice = Strings.tr("Localizable", "PurchasePrice", fallback: "Purchase Price")
  /// Rate: %@/%@
  public static func rate(_ p1: Any, _ p2: Any) -> String {
    return Strings.tr("Localizable", "Rate", String(describing: p1), String(describing: p2), fallback: "Rate: %@/%@")
  }
  /// Remaining Cost: %@
  public static func remainingCost(_ p1: Any) -> String {
    return Strings.tr("Localizable", "RemainingCost", String(describing: p1), fallback: "Remaining Cost: %@")
  }
  /// Remaining days: %@
  public static func remainingDays(_ p1: Any) -> String {
    return Strings.tr("Localizable", "RemainingDays", String(describing: p1), fallback: "Remaining days: %@")
  }
  /// Remaining Value
  public static let remainingValue = Strings.tr("Localizable", "RemainingValue", fallback: "Remaining Value")
  /// Save
  public static let save = Strings.tr("Localizable", "Save", fallback: "Save")
  /// Search Currencies
  public static let searchCurrencies = Strings.tr("Localizable", "SearchCurrencies", fallback: "Search Currencies")
  /// Select Currency
  public static let selectCurrency = Strings.tr("Localizable", "SelectCurrency", fallback: "Select Currency")
  /// Set Default Currency
  public static let setDefaultCurrency = Strings.tr("Localizable", "SetDefaultCurrency", fallback: "Set Default Currency")
  /// Settings
  public static let settings = Strings.tr("Localizable", "Settings", fallback: "Settings")
  /// Submit
  public static let submit = Strings.tr("Localizable", "Submit", fallback: "Submit")
  /// Terms and Conditions
  public static let termsAndConditions = Strings.tr("Localizable", "TermsAndConditions", fallback: "Terms and Conditions")
  /// Theme changes will affect the app's appearance.
  public static let themeFooter = Strings.tr("Localizable", "ThemeFooter", fallback: "Theme changes will affect the app's appearance.")
  /// Total Purchase Value
  public static let totalPurchaseValue = Strings.tr("Localizable", "TotalPurchaseValue", fallback: "Total Purchase Value")
  /// Update
  public static let update = Strings.tr("Localizable", "Update", fallback: "Update")
  /// Updated At
  public static let updatedAt = Strings.tr("Localizable", "UpdatedAt", fallback: "Updated At")
  /// Usage Analytics
  public static let usageAnalytics = Strings.tr("Localizable", "UsageAnalytics", fallback: "Usage Analytics")
  /// Usage Rate
  public static let usageRate = Strings.tr("Localizable", "UsageRate", fallback: "Usage Rate")
  /// Used
  public static let used = Strings.tr("Localizable", "Used", fallback: "Used")
  /// Used for %lld days (%@ %@)
  public static func usedFor(_ p1: Int, _ p2: Any, _ p3: Any) -> String {
    return Strings.tr("Localizable", "UsedFor", p1, String(describing: p2), String(describing: p3), fallback: "Used for %lld days (%@ %@)")
  }
  /// Value Left: %@
  public static func valueLeft(_ p1: Any) -> String {
    return Strings.tr("Localizable", "ValueLeft", String(describing: p1), fallback: "Value Left: %@")
  }
  /// Version
  public static let version = Strings.tr("Localizable", "Version", fallback: "Version")
  /// View Currency Rates
  public static let viewCurrencyRates = Strings.tr("Localizable", "ViewCurrencyRates", fallback: "View Currency Rates")
  /// week
  public static let week = Strings.tr("Localizable", "week", fallback: "week")
  /// year
  public static let year = Strings.tr("Localizable", "year", fallback: "year")
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension Strings {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = Bundle.main.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}
