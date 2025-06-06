# Continuous Integration & Deployment Guide

This document outlines how CI/CD is set up for the Schengen Tracker application.

## GitHub Actions Workflows

The project uses several GitHub Actions workflows:

### 1. Flutter Build, Test & Release (`flutter-build.yml`)

This is the main workflow for building and releasing the app:

- **Trigger**: Runs on pushes to main/master branches and tags starting with 'v'
- **Jobs**:
  - `test`: Runs tests and static analysis
  - `build_android`: Builds the Android APK
  - `build_ios`: Builds the iOS app (only for tagged releases)
  - `release`: Creates GitHub Releases for tagged versions

### 2. Code Quality (`code-quality.yml`)

This workflow performs static code analysis:

- **Trigger**: Runs on pushes to main/master and pull requests
- **Jobs**:
  - `lint`: Runs Flutter analyzer and Dart formatter
  - `metrics`: Runs code metrics tools

### 3. Test Coverage (`coverage.yml`) 

This workflow tracks test coverage:

- **Trigger**: Runs on pushes to main/master and pull requests
- **Job**: Generates and uploads test coverage reports

## Creating Releases

To create a new release:

1. Use the provided `build.sh` script:
   ```bash
   ./build.sh release v1.0.0
   ```

2. This will:
   - Update the version in pubspec.yaml
   - Create and push a git tag
   - Trigger the release workflow in GitHub Actions

## Android Signing

For release signing:

1. **Local Development**:
   - Create a keystore file
   - Add keystore details to `local.properties`:
     ```properties
     keystore.file=/path/to/keystore.jks
     keystore.password=keystorePassword
     key.alias=keyAlias
     key.password=keyPassword
     ```

2. **CI Environment**:
   - Add the following secrets to GitHub:
     - `KEYSTORE_FILE_BASE64`: Base64 encoded keystore file
     - `KEYSTORE_PASSWORD`: Keystore password
     - `KEY_ALIAS`: Key alias
     - `KEY_PASSWORD`: Key password

   - The workflow will decode the keystore file before building.

## iOS Signing

For iOS builds in CI:

1. Add the following secrets to GitHub:
   - `IOS_DISTRIBUTION_CERTIFICATE_BASE64`: Base64 encoded distribution certificate
   - `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD`: Certificate password
   - `IOS_PROVISION_PROFILE_BASE64`: Base64 encoded provisioning profile
   - `APPSTORE_CONNECT_API_KEY_CONTENT`: App Store Connect API key content
   - `APPSTORE_CONNECT_API_KEY_ID`: API key ID
   - `APPSTORE_CONNECT_ISSUER_ID`: Issuer ID

## Local Development

For local development and testing of CI processes:

1. Install required tools:
   ```bash
   flutter pub get
   ```

2. Run tests:
   ```bash
   ./build.sh test
   ```

3. Build APK locally:
   ```bash
   ./build.sh build
   ```
