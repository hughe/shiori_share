{
  "id": "6be090d2",
  "title": "Modernize APIs for macOS 15+",
  "tags": [
    "task"
  ],
  "status": "closed",
  "created_at": "2026-11-06T04:32:41.834Z",
  "priority": 2,
  "slug": "modernize-apis-for-macos-15"
}

Legacy Beads ID: `ss-hr8`

Now that we target macOS 15+, we can use modern SwiftUI APIs and remove workarounds.

Potential improvements:
1. Replace NavigationView with NavigationStack (iOS 16+/macOS 13+)
2. Remove .navigationViewStyle(.stack) - not needed with NavigationStack
3. Use .formStyle(.grouped) for Forms
4. Simplify #if os() conditionals where possible
5. Consider using .onChange(of:) with new signature
6. Use @Observable macro if appropriate (iOS 17+/macOS 14+)

Files to review:
- ShioriShare/InstructionsView.swift
- ShioriShare/SettingsView.swift
- ShioriShare/ShioriShareApp.swift
- ShareExtension/ShareViewController.swift
- Shared/URLExtractor.swift

## Closure

Completed modernization: NavigationStack, .formStyle(.grouped), cleaned up dead code. @Observable evaluation deferred to ss-hr8.4.

## Original Beads record

Original timestamps and metadata are retained below; Pearls timestamps reflect import time.

```json
{
  "id": "ss-hr8",
  "title": "Modernize APIs for macOS 15+",
  "description": "Now that we target macOS 15+, we can use modern SwiftUI APIs and remove workarounds.\n\nPotential improvements:\n1. Replace NavigationView with NavigationStack (iOS 16+/macOS 13+)\n2. Remove .navigationViewStyle(.stack) - not needed with NavigationStack\n3. Use .formStyle(.grouped) for Forms\n4. Simplify #if os() conditionals where possible\n5. Consider using .onChange(of:) with new signature\n6. Use @Observable macro if appropriate (iOS 17+/macOS 14+)\n\nFiles to review:\n- ShioriShare/InstructionsView.swift\n- ShioriShare/SettingsView.swift\n- ShioriShare/ShioriShareApp.swift\n- ShareExtension/ShareViewController.swift\n- Shared/URLExtractor.swift",
  "status": "closed",
  "priority": 2,
  "issue_type": "task",
  "owner": "hugh.emberson@gmail.com",
  "created_at": "2026-01-22T04:59:05.391470Z",
  "created_by": "Hugh Emberson",
  "updated_at": "2026-01-22T07:17:24.938514Z",
  "closed_at": "2026-01-22T07:17:24.938514Z",
  "close_reason": "Completed modernization: NavigationStack, .formStyle(.grouped), cleaned up dead code. @Observable evaluation deferred to ss-hr8.4.",
  "source_repo": ".",
  "compaction_level": 0
}
```
