# DeviceValue

DeviceValue is an iOS application that helps you track and manage your device investments and their depreciation over time. Built with SwiftUI and The Composable Architecture (TCA), it provides a clean and intuitive interface for monitoring your device expenses and usage costs.

## Features

- 📱 Add and manage devices with detailed information
- 💰 Track purchase prices and depreciation
- 📊 Monitor usage rates and costs over time
- 🌐 Support for multiple currencies with automatic conversion
- 📅 Flexible usage rate periods (daily, weekly, monthly, yearly)
- 💾 Persistent storage using GRDB (SQLite)
- 🌓 Support for light and dark mode

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 6.0+

## Dependencies

- [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) (1.17.1+)
- [Swift Dependencies](http://github.com/pointfreeco/swift-dependencies) (1.7.0+)
- [GRDB](https://github.com/groue/GRDB.swift) (7.2.0+)
- [Sharing GRDB](https://github.com/pointfreeco/sharing-grdb) (0.1.0+)

## Project Structure

```
DeviceValueApp/
├── Sources/
│   ├── App/                  # Main application files
│   ├── AddDeviceFeature/     # Add device form and logic
│   ├── AnalyticsFeature/     # Analytics dashboard and insights
│   ├── CurrencyRatesFeature/ # Currency rates management
│   ├── HomeFeature/          # Main home screen
│   ├── Models/               # Data models and database setup
│   ├── SettingsFeature/      # App settings and preferences
│   └── Shared/               # Shared components and utilities
├── Resources/
│   ├── Assets/               # Images and colors
│   └── Localization/         # Localized strings
└── Tests/
    ├── UnitTests/            # Unit tests
    └── UITests/              # UI tests
```

## Architecture

The project follows The Composable Architecture (TCA) pattern, providing:
- Clear separation of concerns
- Predictable state management
- Testable business logic
- Type-safe dependency management

## Database Schema

The application uses SQLite (via GRDB) with the following main tables:
- `devices`: Stores device information and usage metrics
- `currencies`: Manages supported currencies and exchange rates
- `usage_rate_periods`: Defines different rate periods (day, week, month, year)
- `app_settings`: Stores application settings and preferences

## Key Features

### Currency Conversion
DeviceValue automatically converts device costs between currencies using user provided exchange rates, allowing you to see your total device expenses in your preferred currency.

### Cost Calculation
The app calculates the user specified interval usage cost of all your devices, helping you understand your ongoing expenses at a glance.

### Device Sorting
Sort your devices by creation date, name, currency, purchase price, or last update to organize your inventory effectively.

## Getting Started

1. Clone the repository
2. Open the project in Xcode
3. Build and run the project

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Point-Free](https://www.pointfree.co) for The Composable Architecture
- [Gwendal Roué](https://github.com/groue) for GRDB.swift 