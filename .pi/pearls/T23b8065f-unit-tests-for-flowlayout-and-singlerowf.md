{
  "id": "23b8065f",
  "title": "Unit tests for FlowLayout and SingleRowFlowLayout",
  "tags": [
    "task"
  ],
  "status": "closed",
  "created_at": "2026-11-06T04:31:41.652Z",
  "priority": 3,
  "slug": "unit-tests-for-flowlayout-and-singlerowf"
}

Legacy Beads ID: `ss-332`

Test layout calculations:

FlowLayout:
- Single item: positioned at origin
- Items that fit on one row: positioned horizontally with spacing
- Items that wrap: second row starts at correct Y position
- Empty subviews: returns zero size

SingleRowFlowLayout:
- Items that fit: all visible at correct positions
- Items that overflow: visible=false for overflow items
- Overflow items placed offscreen (-10000, -10000)
- Empty subviews: returns zero size

## Closure

Closed

## Relationships

- blocks: T94682abf (legacy `ss-5y7`)

## Original Beads record

Original timestamps and metadata are retained below; Pearls timestamps reflect import time.

```json
{
  "id": "ss-332",
  "title": "Unit tests for FlowLayout and SingleRowFlowLayout",
  "description": "Test layout calculations:\n\nFlowLayout:\n- Single item: positioned at origin\n- Items that fit on one row: positioned horizontally with spacing\n- Items that wrap: second row starts at correct Y position\n- Empty subviews: returns zero size\n\nSingleRowFlowLayout:\n- Items that fit: all visible at correct positions\n- Items that overflow: visible=false for overflow items\n- Overflow items placed offscreen (-10000, -10000)\n- Empty subviews: returns zero size",
  "status": "closed",
  "priority": 3,
  "issue_type": "task",
  "owner": "hugh.emberson@gmail.com",
  "estimated_minutes": 45,
  "created_at": "2026-01-22T18:17:15.449284Z",
  "created_by": "Hugh Emberson",
  "updated_at": "2026-01-22T19:52:29.026183Z",
  "closed_at": "2026-01-22T19:52:29.026183Z",
  "close_reason": "Closed",
  "source_repo": ".",
  "compaction_level": 0,
  "dependencies": [
    {
      "issue_id": "ss-332",
      "depends_on_id": "ss-5y7",
      "type": "blocks",
      "created_at": "2026-01-22T18:17:15.450094Z",
      "created_by": "Hugh Emberson",
      "metadata": "",
      "thread_id": ""
    }
  ]
}
```
