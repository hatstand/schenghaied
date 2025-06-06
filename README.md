# Schengen Zone Tracker

A Flutter application to help travelers track their stays in the Schengen Zone.

![Flutter Build, Test & Release](https://github.com/username/schengen/workflows/Flutter%20Build,%20Test%20%26%20Release/badge.svg)

## Features

- Track entry and exit dates in the Schengen Area
- Calculate days spent and days remaining based on the 90/180 day rule
- View stay history and statistics
- Receive notifications when approaching day limits
- Works offline with local data storage

## Getting Started

### Prerequisites
- Flutter SDK
- Android Studio or Xcode for device deployment

### Installation
1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Connect your device or start an emulator
4. Run `flutter run` to launch the application

## Development

### Architecture
- Flutter state management via Provider
- Local storage with SQLite
- Time Machine package for accurate date handling
- Cross-platform UI components

### Testing
Run the test suite with:
```bash
flutter test
```

### CI/CD Pipeline
This project uses GitHub Actions for automated builds and testing:
- **Continuous Integration**: Every PR and push to main/master branches triggers tests and analysis
- **Automated Builds**: Android APK is built for every PR and push to main
- **Releases**: Tagged versions (e.g., v1.0.0) trigger a GitHub Release with APK artifacts

## Development Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Schengen Calculator Rules](https://ec.europa.eu/home-affairs/policies/schengen-borders-and-visa/border-crossing/short-stay-visa-calculator_en)
- [Time Machine Documentation](https://pub.dev/packages/time_machine)
