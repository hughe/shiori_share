{
  "id": "dc6b3fe6",
  "title": "Create Settings.bundle for iOS Settings app",
  "tags": [
    "task"
  ],
  "status": "closed",
  "created_at": "2026-11-06T04:31:58.925Z",
  "priority": 2,
  "parent": "aa8ad3b5",
  "slug": "create-settings-bundle-for-ios-settings"
}

Legacy Beads ID: `ss-9dj.1`

Create Settings.bundle with Root.plist to expose settings in iOS Settings app.

## Settings to include
- Server URL (text field)
- Username (text field)  
- Create Archive default (toggle, default: on)
- Make Public default (toggle, default: off)
- Trust Self-Signed Certs (toggle, default: off)
- Enable Debug Logging (toggle, default: off)

## Notes
- Use app group UserDefaults for sharing with extension
- Password is NOT included (will be prompted on first use)
- Add to ShioriShare target in Xcode project

## Closure

Closed

## Relationships

- parent-child: Taa8ad3b5 (legacy `ss-9dj`)

## Original Beads record

Original timestamps and metadata are retained below; Pearls timestamps reflect import time.

```json
{
  "id": "ss-9dj.1",
  "title": "Create Settings.bundle for iOS Settings app",
  "description": "Create Settings.bundle with Root.plist to expose settings in iOS Settings app.\n\n## Settings to include\n- Server URL (text field)\n- Username (text field)  \n- Create Archive default (toggle, default: on)\n- Make Public default (toggle, default: off)\n- Trust Self-Signed Certs (toggle, default: off)\n- Enable Debug Logging (toggle, default: off)\n\n## Notes\n- Use app group UserDefaults for sharing with extension\n- Password is NOT included (will be prompted on first use)\n- Add to ShioriShare target in Xcode project",
  "status": "closed",
  "priority": 2,
  "issue_type": "task",
  "owner": "hugh.emberson@gmail.com",
  "created_at": "2026-01-23T05:38:55.977737Z",
  "created_by": "Hugh Emberson",
  "updated_at": "2026-01-23T05:47:17.949956Z",
  "closed_at": "2026-01-23T05:47:17.949956Z",
  "close_reason": "Closed",
  "source_repo": ".",
  "compaction_level": 0,
  "dependencies": [
    {
      "issue_id": "ss-9dj.1",
      "depends_on_id": "ss-9dj",
      "type": "parent-child",
      "created_at": "2026-01-23T05:38:55.978728Z",
      "created_by": "Hugh Emberson",
      "metadata": "",
      "thread_id": ""
    }
  ]
}
```
