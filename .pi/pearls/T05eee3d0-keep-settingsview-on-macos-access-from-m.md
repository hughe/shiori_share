{
  "id": "05eee3d0",
  "title": "Keep SettingsView on macOS, access from menu bar",
  "tags": [
    "task"
  ],
  "status": "closed",
  "created_at": "2026-11-06T04:32:02.767Z",
  "priority": 2,
  "parent": "aa8ad3b5",
  "slug": "keep-settingsview-on-macos-access-from-m"
}

Legacy Beads ID: `ss-9dj.8`

On macOS, keep the SettingsView dialog but access it from the app menu, not a gear icon. Password is NOT entered in settings - prompted on first use like iOS.

## Changes
- Remove gear icon from main window on macOS
- Add Settings menu item to app menu (Cmd+,)
- SettingsView opens as a sheet or separate window from menu
- Remove password field from SettingsView on macOS
- Keep: server URL, username, defaults, debug options in SettingsView

## Password handling (same as iOS)
- Password is prompted on first connection attempt (Test Connection or share extension)
- Stored in keychain after successful login
- Add 'Clear Password' option in settings or menu

## Note
Password entry is now consistent across iOS and macOS - always on first use, never in settings form.

## Closure

Closed

## Relationships

- parent-child: Taa8ad3b5 (legacy `ss-9dj`)

## Original Beads record

Original timestamps and metadata are retained below; Pearls timestamps reflect import time.

```json
{
  "id": "ss-9dj.8",
  "title": "Keep SettingsView on macOS, access from menu bar",
  "description": "On macOS, keep the SettingsView dialog but access it from the app menu, not a gear icon. Password is NOT entered in settings - prompted on first use like iOS.\n\n## Changes\n- Remove gear icon from main window on macOS\n- Add Settings menu item to app menu (Cmd+,)\n- SettingsView opens as a sheet or separate window from menu\n- Remove password field from SettingsView on macOS\n- Keep: server URL, username, defaults, debug options in SettingsView\n\n## Password handling (same as iOS)\n- Password is prompted on first connection attempt (Test Connection or share extension)\n- Stored in keychain after successful login\n- Add 'Clear Password' option in settings or menu\n\n## Note\nPassword entry is now consistent across iOS and macOS - always on first use, never in settings form.",
  "status": "closed",
  "priority": 2,
  "issue_type": "task",
  "owner": "hugh.emberson@gmail.com",
  "created_at": "2026-01-23T05:41:43.093623Z",
  "created_by": "Hugh Emberson",
  "updated_at": "2026-01-23T05:57:11.765309Z",
  "closed_at": "2026-01-23T05:57:11.765309Z",
  "close_reason": "Closed",
  "source_repo": ".",
  "compaction_level": 0,
  "dependencies": [
    {
      "issue_id": "ss-9dj.8",
      "depends_on_id": "ss-9dj",
      "type": "parent-child",
      "created_at": "2026-01-23T05:41:43.094266Z",
      "created_by": "Hugh Emberson",
      "metadata": "",
      "thread_id": ""
    }
  ]
}
```
