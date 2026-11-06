{
  "id": "8676ef59",
  "title": "Update InstructionsView to reference iOS Settings app",
  "tags": [
    "task"
  ],
  "status": "closed",
  "created_at": "2026-11-06T04:32:01.148Z",
  "priority": 2,
  "parent": "aa8ad3b5",
  "slug": "update-instructionsview-to-reference-ios"
}

Legacy Beads ID: `ss-9dj.5`

Update setup instructions to tell users to configure in iOS Settings.

## Changes
- Step 1: Open Settings > Shiori Share
- Step 2: Enter server URL and username
- Step 3: Use share extension (password will be prompted on first use)
- Add deep link button to open Settings app if possible (UIApplication.openSettingsURLString)

## Closure

Closed

## Relationships

- parent-child: Taa8ad3b5 (legacy `ss-9dj`)
- blocks: Tb0d4ac92 (legacy `ss-9dj.4`)

## Original Beads record

Original timestamps and metadata are retained below; Pearls timestamps reflect import time.

```json
{
  "id": "ss-9dj.5",
  "title": "Update InstructionsView to reference iOS Settings app",
  "description": "Update setup instructions to tell users to configure in iOS Settings.\n\n## Changes\n- Step 1: Open Settings > Shiori Share\n- Step 2: Enter server URL and username\n- Step 3: Use share extension (password will be prompted on first use)\n- Add deep link button to open Settings app if possible (UIApplication.openSettingsURLString)",
  "status": "closed",
  "priority": 2,
  "issue_type": "task",
  "owner": "hugh.emberson@gmail.com",
  "created_at": "2026-01-23T05:39:17.020430Z",
  "created_by": "Hugh Emberson",
  "updated_at": "2026-01-23T05:49:28.960107Z",
  "closed_at": "2026-01-23T05:49:28.960107Z",
  "close_reason": "Closed",
  "source_repo": ".",
  "compaction_level": 0,
  "dependencies": [
    {
      "issue_id": "ss-9dj.5",
      "depends_on_id": "ss-9dj",
      "type": "parent-child",
      "created_at": "2026-01-23T05:39:17.021138Z",
      "created_by": "Hugh Emberson",
      "metadata": "",
      "thread_id": ""
    },
    {
      "issue_id": "ss-9dj.5",
      "depends_on_id": "ss-9dj.4",
      "type": "blocks",
      "created_at": "2026-01-23T05:39:33.000621Z",
      "created_by": "Hugh Emberson",
      "metadata": "",
      "thread_id": ""
    }
  ]
}
```
