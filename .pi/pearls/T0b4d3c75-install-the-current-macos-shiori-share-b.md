{
  "id": "0b4d3c75",
  "title": "Install the current macOS Shiori Share build",
  "tags": [
    "maintenance"
  ],
  "status": "closed",
  "created_at": "2026-11-06T04:47:30.081Z",
  "priority": 2,
  "closed_at": "2026-11-06T04:50:47.722Z",
  "slug": "install-the-current-macos-shiori-share-b"
}

# Install the current macOS Shiori Share build

## Description

Build and verify the current signed macOS app, replace the existing /Applications/ShioriShare.app installation while retaining a backup, and launch it.

make build-macos passed. Verified the signed app and nested extension with codesign --verify --deep --strict. Replaced /Applications/ShioriShare.app and launched it with open. Installed debug library hash matches the build. macOS pluginkit lists the extension at /Applications/ShioriShare.app/Contents/PlugIns/ShareExtension.appex, and an installed extension process was observed. Previous app backed up at /private/tmp/shiori-macos-install.fQenVG/Previous-ShioriShare.app.

User confirmed the installed macOS build works against the Shiori v1.8.0 test environment.

User also confirmed the iOS build works against the Shiori v1.8.0 test environment.
