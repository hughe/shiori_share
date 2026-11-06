{
  "id": "dd7e9c65",
  "title": "Release version 0.4.0 and show it in the app",
  "tags": [
    "release"
  ],
  "status": "closed",
  "created_at": "2026-11-06T04:56:46.727Z",
  "priority": 2,
  "closed_at": "2026-11-06T04:57:41.152Z",
  "slug": "release-version-0-4-0-and-show-it-in-the"
}

# Release version 0.4.0 and show it in the app

## Description

Set app and extension marketing versions to 0.4.0, show the bundle version in the shared iOS/macOS main screen and macOS About panel, verify builds, and tag and push the release commit as v0.4.0. Preserve unrelated local Xcode changes.

Set all target Debug/Release marketing versions to 0.4.0. The shared instructions header displays Version 0.4.0 using CFBundleShortVersionString, and the macOS About panel uses the same value. make build-sim and make build-macos passed. Verified app and embedded extension versions are 0.4.0 in both built products. Stage only version changes from project.pbxproj to preserve unrelated local Xcode updates.

Installed the signed 0.4.0 macOS build at /Applications/ShioriShare.app at the user’s request and launched it. Verified installed CFBundleShortVersionString is 0.4.0 and codesign verification passed. Previous installation backed up at /private/tmp/shiori-macos-v040.w7QjND/Previous-ShioriShare.app.
