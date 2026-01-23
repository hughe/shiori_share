# Shiori Share

A native iOS and macOS share extension for [Shiori](https://github.com/go-shiori/shiori), the simple self-hosted bookmark manager.

## Features

- **Share Extension**: Save bookmarks directly from Safari or any app with a share button
- **Native Experience**: iOS uses the Settings app for configuration; macOS uses the standard Settings menu
- **Secure**: Password stored in the system Keychain, prompted only on first use
- **Tags**: Add tags to bookmarks with autocomplete from your existing tags
- **Archive**: Optionally create offline archives of bookmarked pages
- **Self-Signed Certs**: Support for self-hosted servers with self-signed certificates

## Requirements

- iOS 18.0+ / macOS 15.0+
- A running [Shiori](https://github.com/go-shiori/shiori) server

## Installation

### From Source

1. Clone this repository
2. Open `ShioriShare.xcodeproj` in Xcode
3. Select your development team in Signing & Capabilities
4. Build and run on your device

```bash
# Build for iOS Simulator
make build-sim

# Build for iOS device
make build-ios

# Build for macOS
make build-macos
```

## Setup

### iOS

1. Open the Shiori Share app
2. Tap **Open Settings** to configure in the iOS Settings app
3. Enter your Shiori server URL (e.g., `https://shiori.example.com`)
4. Enter your username
5. Use **Test Connection** to verify (you'll be prompted for your password)

### macOS

1. Open the Shiori Share app
2. Open **Settings** from the menu bar (⌘,)
3. Enter your server URL and username
4. Click **Test Connection** to verify and save your password

## Usage

1. In Safari (or any browser), tap/click the **Share** button
2. Select **Shiori Share** from the share sheet
3. Enter your password if prompted (first time only)
4. Add tags and a description if desired
5. Tap/Click **Save** to bookmark the page

### Tips

- To move Shiori Share higher in the share sheet on iOS, scroll right and tap "More", then tap "Edit" to reorder
- Use the "Reset Password" toggle in iOS Settings to clear your saved password
- On macOS, use the "Clear" button in Settings to remove your saved password

## Configuration Options

| Setting | Description | Default |
|---------|-------------|---------|
| Server URL | Your Shiori server address | - |
| Username | Your Shiori username | - |
| Create Archive | Save offline copy of pages | On |
| Make Public | Make bookmarks publicly visible | Off |
| Trust Self-Signed Certs | Allow self-signed SSL certificates | Off |
| Enable Debug Logging | Save detailed logs for troubleshooting | Off |

## Building

```bash
# Build for iOS Simulator
make build-sim

# Build for iOS device (requires signing)
make build-ios

# Build for macOS (requires signing)
make build-macos

# Open in Xcode
make open

# Clean build artifacts
make clean
```

## Testing

```bash
xcodebuild test -project ShioriShare.xcodeproj -scheme ShioriShare \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Project Structure

```
ShioriShare/
├── ShioriShare/           # Main app (Instructions + Settings on macOS)
│   ├── Settings.bundle/   # iOS Settings app integration
│   ├── InstructionsView.swift
│   ├── SettingsView.swift # macOS only
│   └── ...
├── ShareExtension/        # Share extension
│   └── ShareViewController.swift
├── Shared/                # Shared code
│   ├── ShioriAPI.swift    # API client
│   ├── KeychainHelper.swift
│   ├── SettingsManager.swift
│   └── ...
└── ShioriShareTests/      # Unit tests
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- [Shiori](https://github.com/go-shiori/shiori) - The bookmark manager this app connects to
