{
  "id": "aa8ad3b5",
  "title": "Refactor settings to use iOS Settings.bundle",
  "tags": [
    "epic"
  ],
  "status": "closed",
  "created_at": "2026-11-06T04:31:58.391Z",
  "priority": 2,
  "slug": "refactor-settings-to-use-ios-settings-bu"
}

Legacy Beads ID: `ss-9dj`

Move settings from in-app SettingsView to native iOS Settings app using Settings.bundle. Password should be prompted on first use of share extension and stored in keychain, not entered through a settings form.

## Goals
1. Use iOS Settings app for configuration (server URL, username, defaults, debug options)
2. Remove SettingsView.swift from main app
3. Prompt for password on first share extension use, store in keychain
4. Maintain macOS settings experience (Settings.bundle is iOS-only)

## Benefits
- Native iOS experience
- Settings accessible from iOS Settings app
- Password entry only when needed (more secure UX)
- Simpler main app (instructions only)

## Closure

Closed

## Original Beads record

Original timestamps and metadata are retained below; Pearls timestamps reflect import time.

```json
{
  "id": "ss-9dj",
  "title": "Refactor settings to use iOS Settings.bundle",
  "description": "Move settings from in-app SettingsView to native iOS Settings app using Settings.bundle. Password should be prompted on first use of share extension and stored in keychain, not entered through a settings form.\n\n## Goals\n1. Use iOS Settings app for configuration (server URL, username, defaults, debug options)\n2. Remove SettingsView.swift from main app\n3. Prompt for password on first share extension use, store in keychain\n4. Maintain macOS settings experience (Settings.bundle is iOS-only)\n\n## Benefits\n- Native iOS experience\n- Settings accessible from iOS Settings app\n- Password entry only when needed (more secure UX)\n- Simpler main app (instructions only)",
  "status": "closed",
  "priority": 2,
  "issue_type": "epic",
  "owner": "hugh.emberson@gmail.com",
  "created_at": "2026-01-23T05:38:49.911133Z",
  "created_by": "Hugh Emberson",
  "updated_at": "2026-01-23T05:57:20.514380Z",
  "closed_at": "2026-01-23T05:57:20.514380Z",
  "close_reason": "Closed",
  "source_repo": ".",
  "compaction_level": 0
}
```
