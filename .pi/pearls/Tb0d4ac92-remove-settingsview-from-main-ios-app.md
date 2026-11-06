{
  "id": "b0d4ac92",
  "title": "Remove SettingsView from main iOS app",
  "tags": [
    "task"
  ],
  "status": "closed",
  "created_at": "2026-11-06T04:32:00.594Z",
  "priority": 2,
  "parent": "aa8ad3b5",
  "slug": "remove-settingsview-from-main-ios-app"
}

Legacy Beads ID: `ss-9dj.4`

Remove in-app settings UI for iOS. Main app becomes instructions-only.

## Changes
- Remove SettingsView.swift from iOS build (keep for macOS)
- Update InstructionsView.swift to remove 'Configure Settings' button on iOS
- Update ContentView.swift if needed
- Keep SettingsView.swift for macOS target (use #if os(macOS))

## Result
iOS main app shows only setup instructions pointing to Settings app

## Closure

Closed

## Relationships

- parent-child: Taa8ad3b5 (legacy `ss-9dj`)
- blocks: Tdc6b3fe6 (legacy `ss-9dj.1`)

## Original Beads record

Original timestamps and metadata are retained below; Pearls timestamps reflect import time.

```json
{
  "id": "ss-9dj.4",
  "title": "Remove SettingsView from main iOS app",
  "description": "Remove in-app settings UI for iOS. Main app becomes instructions-only.\n\n## Changes\n- Remove SettingsView.swift from iOS build (keep for macOS)\n- Update InstructionsView.swift to remove 'Configure Settings' button on iOS\n- Update ContentView.swift if needed\n- Keep SettingsView.swift for macOS target (use #if os(macOS))\n\n## Result\niOS main app shows only setup instructions pointing to Settings app",
  "status": "closed",
  "priority": 2,
  "issue_type": "task",
  "owner": "hugh.emberson@gmail.com",
  "created_at": "2026-01-23T05:39:12.249475Z",
  "created_by": "Hugh Emberson",
  "updated_at": "2026-01-23T05:49:28.934253Z",
  "closed_at": "2026-01-23T05:49:28.934253Z",
  "close_reason": "Closed",
  "source_repo": ".",
  "compaction_level": 0,
  "dependencies": [
    {
      "issue_id": "ss-9dj.4",
      "depends_on_id": "ss-9dj",
      "type": "parent-child",
      "created_at": "2026-01-23T05:39:12.250078Z",
      "created_by": "Hugh Emberson",
      "metadata": "",
      "thread_id": ""
    },
    {
      "issue_id": "ss-9dj.4",
      "depends_on_id": "ss-9dj.1",
      "type": "blocks",
      "created_at": "2026-01-23T05:39:32.889437Z",
      "created_by": "Hugh Emberson",
      "metadata": "",
      "thread_id": ""
    }
  ]
}
```
