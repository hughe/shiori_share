{
  "id": "26e329a4",
  "title": "Move Test Connection button to main app window",
  "tags": [
    "task"
  ],
  "status": "closed",
  "created_at": "2026-11-06T04:32:02.226Z",
  "priority": 2,
  "parent": "aa8ad3b5",
  "slug": "move-test-connection-button-to-main-app"
}

Legacy Beads ID: `ss-9dj.7`

Move the Test Connection functionality from SettingsView to the main app window (InstructionsView or ContentView).

## Implementation
- Add 'Test Connection' button to main iOS app UI
- Read server URL and username from Settings.bundle/UserDefaults
- Prompt for password if not in keychain (or use stored password)
- Show success/failure status inline
- Useful for users to verify setup before first share

## Closure

Closed

## Relationships

- parent-child: Taa8ad3b5 (legacy `ss-9dj`)
- blocks: Tb0d4ac92 (legacy `ss-9dj.4`)

## Original Beads record

Original timestamps and metadata are retained below; Pearls timestamps reflect import time.

```json
{
  "id": "ss-9dj.7",
  "title": "Move Test Connection button to main app window",
  "description": "Move the Test Connection functionality from SettingsView to the main app window (InstructionsView or ContentView).\n\n## Implementation\n- Add 'Test Connection' button to main iOS app UI\n- Read server URL and username from Settings.bundle/UserDefaults\n- Prompt for password if not in keychain (or use stored password)\n- Show success/failure status inline\n- Useful for users to verify setup before first share",
  "status": "closed",
  "priority": 2,
  "issue_type": "task",
  "owner": "hugh.emberson@gmail.com",
  "created_at": "2026-01-23T05:40:03.413765Z",
  "created_by": "Hugh Emberson",
  "updated_at": "2026-01-23T05:57:11.737955Z",
  "closed_at": "2026-01-23T05:57:11.737955Z",
  "close_reason": "Closed",
  "source_repo": ".",
  "compaction_level": 0,
  "dependencies": [
    {
      "issue_id": "ss-9dj.7",
      "depends_on_id": "ss-9dj",
      "type": "parent-child",
      "created_at": "2026-01-23T05:40:03.417934Z",
      "created_by": "Hugh Emberson",
      "metadata": "",
      "thread_id": ""
    },
    {
      "issue_id": "ss-9dj.7",
      "depends_on_id": "ss-9dj.4",
      "type": "blocks",
      "created_at": "2026-01-23T05:40:07.235947Z",
      "created_by": "Hugh Emberson",
      "metadata": "",
      "thread_id": ""
    }
  ]
}
```
