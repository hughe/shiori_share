# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Shiori Share is a cross-platform (iOS/macOS) SwiftUI app and share extension for saving bookmarks to a self-hosted Shiori bookmark manager server. The app provides a native share sheet integration that extracts URLs from shared content and submits them to Shiori via REST API.

## Additional Documentation

- **AGENTS.md** - Agent-specific instructions including session completion workflow, quality gates, and commit/PR guidelines
- **PLAN.md** - Comprehensive development plan with detailed UI mockups, API integration specs, phase-by-phase implementation guide, and troubleshooting

## Build Commands

```bash
# Build for iOS Simulator (default target)
make build-sim

# Build for iOS device
make build-ios

# Build for macOS
make build-macos

# Run unit tests
make test

# Clean build artifacts
make clean

# Open project in Xcode
make open
```

### Running Single Tests

```bash
# Run a specific test class
xcodebuild test -project ShioriShare.xcodeproj \
  -scheme ShioriShare \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:ShioriShareTests/StringURLTests

# Run a specific test method
xcodebuild test -project ShioriShare.xcodeproj \
  -scheme ShioriShare \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:ShioriShareTests/StringURLTests/testExtractedURL
```

## Architecture

### Three-Target Structure

1. **ShioriShare** (Main App)
   - Entry point: `ShioriShareApp.swift`
   - Settings configuration UI (`SettingsView.swift`)
   - Instructions screen (`InstructionsView.swift`)
   - Used for initial setup and configuration only

2. **ShareExtension** (Share Extension)
   - Entry point: `ShareViewController.swift` (wraps `ShareExtensionView`)
   - Activated via iOS/macOS share sheet
   - Extracts URLs from shared content
   - Presents bookmark form UI
   - Submits bookmarks to Shiori server

3. **Shared** (Shared Code)
   - Core business logic shared between app and extension
   - API client, settings management, keychain access

### Data Sharing Architecture

The app and share extension communicate via **App Groups** and **Keychain Sharing**:

- **App Group ID**: `group.net.emberson.shiorishare`
  - Used for `UserDefaults` storage (server URL, username, preferences)
  - Managed by `SettingsManager.shared`

- **Keychain Access Group**: `net.emberson.shiorishare.shared`
  - Used for secure password storage only
  - Managed by `KeychainHelper.shared`
  - Note: Access group sharing doesn't work on iOS Simulator

### Key Components

**ShioriAPI** (`Shared/ShioriAPI.swift`)
- Singleton REST API client for Shiori server
- Handles authentication (session-based with 1-hour cache)
- Endpoints: login (`/api/v1/auth/login`), bookmarks (`/api/bookmarks`), tags (`/api/tags`)
- Automatic session refresh when expired
- Self-signed certificate support via `TrustSelfSignedCertificatesDelegate`
- Centralized status code handling with `mapStatusCode()` method

**SettingsManager** (`Shared/SettingsManager.swift`)
- Singleton for non-sensitive settings storage
- Uses `UserDefaults` with App Group suite
- Stores: server URL, username, default preferences, tag cache, session cache
- Passwords stored separately in Keychain

**KeychainHelper** (`Shared/KeychainHelper.swift`)
- Singleton for secure credential storage
- Only stores password (other settings use UserDefaults)
- Implements caching to minimize keychain access
- Access group sharing for app/extension communication

**URLExtractor** (`Shared/URLExtractor.swift`)
- Extracts URLs and titles from `NSExtensionContext`
- Tries multiple extraction strategies: direct URL, plain text with URL extraction
- Uses `String.extractedURL` extension for text parsing

### Session Management

- Sessions obtained via POST to `/api/v1/auth/login`
- Sessions cached for 1 hour in `SettingsManager`
- Automatic re-login when 401 received (except during login itself)
- Session cleared on 401 to trigger fresh login

### Tag System

- Tags are comma-separated strings in the UI
- Parsed by `ShioriAPI.parseKeywords()` into `TagObject` array
- Recent tags cached in `SettingsManager` (max 50, display 10)
- Popular tags fetched from server and cached
- Autocomplete suggestions based on cached tags

## Code Patterns

### Platform-Specific Code

Use conditional compilation for iOS/macOS differences:

```swift
#if os(iOS)
// iOS-specific code
#elseif os(macOS)
// macOS-specific code
#endif
```

### Async/Await API Calls

All network calls use modern Swift concurrency:

```swift
let response = try await ShioriAPI.shared.addBookmark(
    url: url,
    title: title,
    description: description,
    keywords: keywords,
    createArchive: createArchive,
    makePublic: makePublic
)
```

### Error Handling

- Custom `ShioriAPIError` enum for API errors
- All errors include user-facing `localizedDescription`
- `isRetryable` property determines if retry UI should be shown

### URL Path Construction

Always use `URL.appendingPathSafely()` instead of `appendingPathComponent()` to avoid double-slash issues:

```swift
let loginURL = baseURL.appendingPathSafely(AppConstants.API.loginPath)
```

## Testing

Current test coverage:
- `StringURLTests` - String+URL extensions (URL validation, extraction)
- `ParseKeywordsTests` - Tag parsing logic

When adding tests:
- Place in `ShioriShareTests/` directory
- Import `@testable import ShioriShare`
- Follow existing naming conventions (`test<FunctionName><Scenario>`)

## Issue Tracking

This project uses **beads** (bd) for issue tracking. See `.beads/README.md` for details.

Quick reference:
```bash
bd ready              # Show available work
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git remote
```

## Important Notes

- **Simulator Limitation**: Keychain access group sharing doesn't work on iOS Simulator. Use device for testing credential sharing between app and extension.
- **API Versions**: Login uses v1 API (`/api/v1/auth/login`), bookmarks use legacy API (`/api/bookmarks`) for stability.
- **Session Security**: Sessions are X-Session-Id header-based, not cookie-based.
- **Certificate Trust**: Self-signed certificate trust applies to specific host only, configured via `TrustSelfSignedCertificatesDelegate`.
