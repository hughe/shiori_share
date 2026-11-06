{
  "id": "427d9045",
  "title": "macOS Share Extension: Replace UIKit with AppKit",
  "tags": [
    "task"
  ],
  "status": "closed",
  "created_at": "2026-11-06T04:32:45.607Z",
  "priority": 2,
  "slug": "macos-share-extension-replace-uikit-with"
}

Legacy Beads ID: `ss-n1q`

The ShareExtension currently uses UIKit which is not available on macOS. Need to:

1. Create a macOS-specific share extension target or use conditional compilation
2. Replace UIViewController with NSViewController
3. Replace UIHostingController with NSHostingController
4. Handle platform differences in the SwiftUI views (e.g., haptic feedback is iOS-only)
5. Test share extension works from Safari on macOS

Current error when building for macOS:
```
ShareViewController.swift:1:8: error: Unable to find module dependency: 'UIKit'
```

Options:
- Use #if os(iOS) / #if os(macOS) conditional compilation
- Create separate ShareExtension-macOS target
- Use Catalyst (but share extensions have limitations)

## Closure

Added conditional compilation for macOS support: replaced UIKit with AppKit, wrapped iOS-specific APIs (haptics, keyboard types, autocapitalization), duplicated URLExtractor methods for macOS

## Original Beads record

Original timestamps and metadata are retained below; Pearls timestamps reflect import time.

```json
{
  "id": "ss-n1q",
  "title": "macOS Share Extension: Replace UIKit with AppKit",
  "description": "The ShareExtension currently uses UIKit which is not available on macOS. Need to:\n\n1. Create a macOS-specific share extension target or use conditional compilation\n2. Replace UIViewController with NSViewController\n3. Replace UIHostingController with NSHostingController\n4. Handle platform differences in the SwiftUI views (e.g., haptic feedback is iOS-only)\n5. Test share extension works from Safari on macOS\n\nCurrent error when building for macOS:\n```\nShareViewController.swift:1:8: error: Unable to find module dependency: 'UIKit'\n```\n\nOptions:\n- Use #if os(iOS) / #if os(macOS) conditional compilation\n- Create separate ShareExtension-macOS target\n- Use Catalyst (but share extensions have limitations)",
  "status": "closed",
  "priority": 2,
  "issue_type": "task",
  "owner": "hugh.emberson@gmail.com",
  "created_at": "2026-01-21T02:00:43.730126Z",
  "created_by": "Hugh Emberson",
  "updated_at": "2026-01-22T01:40:46.657389Z",
  "closed_at": "2026-01-22T01:40:46.657389Z",
  "close_reason": "Added conditional compilation for macOS support: replaced UIKit with AppKit, wrapped iOS-specific APIs (haptics, keyboard types, autocapitalization), duplicated URLExtractor methods for macOS",
  "source_repo": ".",
  "compaction_level": 0
}
```
