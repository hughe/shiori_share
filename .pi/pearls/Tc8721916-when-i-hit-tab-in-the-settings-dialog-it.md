{
  "id": "c8721916",
  "title": "when I hit tab in the settings dialog, it cycles between the server URL field, the username field and the password field. It doesn't go to the default settings fields or test connection.",
  "tags": [
    "feature"
  ],
  "status": "closed",
  "created_at": "2026-11-06T04:32:18.484Z",
  "priority": 0,
  "slug": "when-i-hit-tab-in-the-settings-dialog-it"
}

Legacy Beads ID: `ss-bhz`

I should be able to navigate to all the way down to the save button by pushing tab.

also, the URL, username and password fields do not have labels.


## Closure

Added @FocusState for full tab navigation through all fields (text fields, toggles, buttons). Added .onSubmit to text fields for Return-to-advance. Added .onExitCommand for Escape to close dialog.

## Original Beads record

Original timestamps and metadata are retained below; Pearls timestamps reflect import time.

```json
{
  "id": "ss-bhz",
  "title": "when I hit tab in the settings dialog, it cycles between the server URL field, the username field and the password field. It doesn't go to the default settings fields or test connection.",
  "description": "I should be able to navigate to all the way down to the save button by pushing tab.\n\nalso, the URL, username and password fields do not have labels.\n",
  "status": "closed",
  "priority": 0,
  "issue_type": "feature",
  "owner": "hugh.emberson@gmail.com",
  "created_at": "2026-01-22T04:54:00.318660Z",
  "created_by": "Hugh Emberson",
  "updated_at": "2026-01-22T05:10:31.247417Z",
  "closed_at": "2026-01-22T05:10:31.247417Z",
  "close_reason": "Added @FocusState for full tab navigation through all fields (text fields, toggles, buttons). Added .onSubmit to text fields for Return-to-advance. Added .onExitCommand for Escape to close dialog.",
  "source_repo": ".",
  "compaction_level": 0
}
```
