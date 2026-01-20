# Shiori Share - Development Plan

## Project Overview

**App Name**: Shiori Share  
**Purpose**: iOS/iPadOS/macOS app to save bookmarks from Safari (and other apps) to a Shiori bookmark manager server via the share sheet.

**Bundle IDs**:
- Main App: `net.emberson.shiorishare`
- Share Extension: `net.emberson.shiorishare.ShareExtension`
- App Group: `group.net.emberson.shiorishare`
- Keychain Access Group: `net.emberson.shiorishare.shared`

**Target Platforms**:
- iOS 15.0+
- iPadOS 15.0+
- macOS 12.0+ (Monterey)

**Recommendation**: Start with iOS/iPadOS, then add macOS support.

---

## Architecture Overview

### Components

1. **Main App** - Two screen app for configuration
   - Screen 1: Instructions/Welcome
   - Screen 2: Settings (Server configuration)

2. **Share Extension** - Bookmark capture form
   - Receives URL and title from share sheet
   - Collects metadata from user
   - Sends to Shiori server

3. **Shared Storage**
   - Keychain: Server URL, username, password (secured)
   - App Group UserDefaults: Default preferences (createArchive, makePublic)

4. **Shiori API Client** - Handles authentication and bookmark creation

---

## Data Storage

### Keychain (Shared via Keychain Access Group)
- Key: `shiori.serverURL` → Value: "https://shiori.example.com"
- Key: `shiori.username` → Value: "username"
- Key: `shiori.password` → Value: "password"

### UserDefaults (Shared via App Group)
- Key: `defaultCreateArchive` → Value: Bool (default: true)
- Key: `defaultMakePublic` → Value: Bool (default: false)

---

## Shiori API Integration

### API Choice
Use the **Old/Legacy API** (stable, well-documented)
- Base documentation: https://github.com/go-shiori/shiori/blob/master/docs/API.md
- The new v1 API is still in development

### Authentication Flow

**Endpoint**: `POST {serverURL}/api/login`

**Request**:
```json
{
  "username": "shiori",
  "password": "gopher",
  "remember": true
}
```

**Response**:
```json
{
  "session": "YOUR_SESSION_ID",
  "account": {
    "id": 1,
    "username": "shiori",
    "owner": true
  }
}
```

### Add Bookmark Flow

**Endpoint**: `POST {serverURL}/api/bookmarks`

**Headers**:
- `X-Session-Id`: session ID from login
- `Content-Type`: application/json

**Request Body**:
```json
{
  "url": "https://example.com/article",
  "excerpt": "Description text here",
  "tags": [{"name": "tag1"}, {"name": "tag2"}],
  "createArchive": true,
  "public": 1
}
```

**Important Notes**:
- `public` field uses integers: `1` for public, `0` for private (not boolean)
- `tags` must be array of objects with "name" key: `[{"name": "tag1"}]`
- Shiori may ignore provided title and fetch automatically
- `excerpt` maps to our "description" field

---

## Main App UI Design

### Screen 1: Instructions/Welcome

```
┌─────────────────────────────────┐
│   Shiori Share            [⚙️]  │
├─────────────────────────────────┤
│                                 │
│  📚 Shiori Share                 │
│                                 │
│  Save bookmarks from Safari     │
│  to your Shiori server          │
│                                 │
│  ───────────────────────────    │
│                                 │
│  📱 How to Use                   │
│                                 │
│  1. Tap the ⚙️ button above     │
│     to configure your server    │
│                                 │
│  2. In Safari, tap the share    │
│     button on any page          │
│                                 │
│  3. Select "Shiori Share"       │
│     from the share sheet        │
│                                 │
│  4. Add tags and details,       │
│     then tap Save               │
│                                 │
│  ───────────────────────────    │
│                                 │
│  ℹ️ About Shiori                 │
│                                 │
│  Shiori is a simple bookmark    │
│  manager built with Go.         │
│                                 │
│  Learn more at:                 │
│  github.com/go-shiori/shiori    │
│                                 │
└─────────────────────────────────┘
```

**Navigation**: 
- Gear icon (⚙️) in top-right navigation bar
- Tapping navigates to Settings screen

### Screen 2: Settings/Configuration

```
┌─────────────────────────────────┐
│  ← Settings                     │
├─────────────────────────────────┤
│                                 │
│  Server Configuration           │
│                                 │
│  Server URL                     │
│  ┌───────────────────────────┐ │
│  │https://shiori.example.com │ │
│  └───────────────────────────┘ │
│                                 │
│  Username                       │
│  ┌───────────────────────────┐ │
│  │                           │ │
│  └───────────────────────────┘ │
│                                 │
│  Password                       │
│  ┌───────────────────────────┐ │
│  │ •••••••••••••            │ │
│  └───────────────────────────┘ │
│                                 │
│  ───────────────────────────    │
│                                 │
│  Default Settings               │
│                                 │
│  ☑️ Create Archive              │
│  ☐ Make Public                  │
│                                 │
│  ───────────────────────────    │
│                                 │
│  [Test Connection]  [Save]      │
│                                 │
│  ⚠️ Error: Could not connect    │
│     to server. Check URL.       │
│                                 │
└─────────────────────────────────┘
```

**Features**:
- Form with server URL, username, password fields
- Two toggles for default preferences
- "Test Connection" button (validates credentials with Shiori API)
- "Save" button (saves to Keychain and UserDefaults)
- Status message area for success/error feedback

**Validation**:
- Server URL must start with http:// or https://
- All fields required before saving
- Test Connection makes actual API call to verify credentials

---

## Share Extension UI Design

### Main Form (Editing State)

```
┌─────────────────────────────────┐
│  Save to Shiori          [✕]   │
├─────────────────────────────────┤
│                                 │
│  URL                            │
│  https://example.com/article    │
│                                 │
│  ───────────────────────────    │
│                                 │
│  Title                          │
│  ┌───────────────────────────┐ │
│  │ Interesting Article Title │ │
│  └───────────────────────────┘ │
│                                 │
│  Description (optional)         │
│  ┌───────────────────────────┐ │
│  │                           │ │
│  │                           │ │
│  │                           │ │
│  └───────────────────────────┘ │
│                                 │
│  Keywords (optional)            │
│  ┌───────────────────────────┐ │
│  │ tag1, tag2, tag3          │ │
│  └───────────────────────────┘ │
│                                 │
│  ☑️ Create Archive              │
│  ☐ Make Public                  │
│                                 │
│  ───────────────────────────    │
│                                 │
│      [Cancel]      [Save]       │
│                                 │
└─────────────────────────────────┘
```

**Fields**:
- URL (read-only, extracted from share)
- Title (editable, pre-filled from page title if available)
- Description (optional, multiline, 2-3 lines)
- Keywords (optional, comma-separated)
- Create Archive (toggle, default from settings)
- Make Public (toggle, default from settings)

### Saving State

```
┌─────────────────────────────────┐
│  Save to Shiori          [✕]   │
├─────────────────────────────────┤
│                                 │
│                                 │
│         🔄                       │
│                                 │
│    Saving bookmark...           │
│                                 │
│                                 │
└─────────────────────────────────┘
```

### Success State

```
┌─────────────────────────────────┐
│  Save to Shiori          [✕]   │
├─────────────────────────────────┤
│                                 │
│                                 │
│         ✅                       │
│                                 │
│  Bookmark saved successfully!   │
│                                 │
│  Auto-closing...                │
│                                 │
└─────────────────────────────────┘
```

**Behavior**: Auto-close after 1.5 seconds

### Error States

#### Server Not Configured
```
┌─────────────────────────────────┐
│  Save to Shiori          [✕]   │
├─────────────────────────────────┤
│                                 │
│         ⚠️                       │
│                                 │
│  Server Not Configured          │
│                                 │
│  Please open the Shiori Share   │
│  app to configure your server   │
│  credentials.                   │
│                                 │
│                                 │
│           [OK]                  │
│                                 │
└─────────────────────────────────┘
```

#### Connection Failed
```
┌─────────────────────────────────┐
│  Save to Shiori          [✕]   │
├─────────────────────────────────┤
│                                 │
│         ⚠️                       │
│                                 │
│  Connection Failed              │
│                                 │
│  Could not connect to server.   │
│  Please check your network      │
│  connection and server URL.     │
│                                 │
│                                 │
│      [Cancel]    [Retry]        │
│                                 │
└─────────────────────────────────┘
```

#### Authentication Failed
```
┌─────────────────────────────────┐
│  Save to Shiori          [✕]   │
├─────────────────────────────────┤
│                                 │
│         ⚠️                       │
│                                 │
│  Authentication Failed          │
│                                 │
│  Invalid username or password.  │
│  Please update your credentials │
│  in the Shiori Share app.       │
│                                 │
│                                 │
│           [OK]                  │
│                                 │
└─────────────────────────────────┘
```

#### Server Error
```
┌─────────────────────────────────┐
│  Save to Shiori          [✕]   │
├─────────────────────────────────┤
│                                 │
│         ⚠️                       │
│                                 │
│  Server Error                   │
│                                 │
│  The Shiori server returned     │
│  an error (500).                │
│                                 │
│  Please try again later.        │
│                                 │
│      [Cancel]    [Retry]        │
│                                 │
└─────────────────────────────────┘
```

---

## Error Handling Flow

```
User taps Save
     ↓
Validate credentials exist in Keychain
     ├─ NO → Show "Server Not Configured" error
     └─ YES → Continue
           ↓
     Validate URL from share
           ├─ NO → Show "Invalid Input" error
           └─ YES → Continue
                 ↓
           Show "Saving..." spinner
                 ↓
           Attempt login to Shiori
                 ├─ 401/403 → Show "Authentication Failed" error
                 ├─ Network error → Show "Connection Failed" error with Retry
                 └─ Success → Continue
                       ↓
                 Attempt save bookmark
                       ├─ 500/503 → Show "Server Error" with Retry
                       ├─ 4xx → Show error with message
                       ├─ Network error → Show "Connection Failed" with Retry
                       └─ Success → Show "Success!" and auto-close after 1.5s
```

### Error Categorization

| Error Type | User Actions | Auto-Close | Retry Allowed |
|------------|--------------|------------|---------------|
| Server Not Configured | OK | No | No |
| Invalid Input | OK | No | No |
| Authentication Failed | OK | No | No |
| Connection Failed | Cancel, Retry | No | Yes |
| Server Error | Cancel, Retry | No | Yes |
| Success | (none) | Yes (1.5s) | N/A |

---

## Development Phases

### Phase 1: Project Setup
- [ ] Create multiplatform Xcode project (iOS + macOS)
- [ ] Configure Bundle IDs
- [ ] Add Share Extension target
- [ ] Enable App Groups capability for both targets
  - Group ID: `group.net.emberson.shiorishare`
- [ ] Enable Keychain Sharing capability for both targets
  - Access Group: `net.emberson.shiorishare.shared`
- [ ] Set minimum deployment targets (iOS 15.0, macOS 12.0)
- [ ] Set up project structure with Shared folder

### Phase 2: Keychain Helper & Storage
- [ ] Create `KeychainHelper.swift` utility class
- [ ] Implement save/read/delete methods for credentials
- [ ] Add error handling for Keychain operations
- [ ] Test Keychain access from both main app and extension
- [ ] Create `SettingsManager.swift` for UserDefaults access

### Phase 3: Shiori API Client
- [ ] Create `ShioriAPI.swift` client
- [ ] Implement login method (`POST /api/login`)
- [ ] Implement add bookmark method (`POST /api/bookmarks`)
- [ ] Add proper error handling and typed errors
- [ ] Parse keywords into tags array format
- [ ] Handle public field as integer (0/1)
- [ ] Add unit tests for API client

### Phase 4: Main App - Instructions Screen
- [ ] Create `InstructionsView.swift`
- [ ] Add welcome text and app description
- [ ] Add step-by-step usage instructions
- [ ] Add "About Shiori" section with link
- [ ] Add navigation bar with gear icon
- [ ] Navigation to Settings screen

### Phase 5: Main App - Settings Screen
- [ ] Create `SettingsView.swift`
- [ ] Add form with server URL, username, password fields
- [ ] Add validation for URL format (must start with http/https)
- [ ] Add Create Archive and Make Public toggles
- [ ] Implement "Save" button
  - Save credentials to Keychain
  - Save defaults to UserDefaults
  - Show success/error message
- [ ] Implement "Test Connection" button
  - Call Shiori login API
  - Show success/error message
- [ ] Load existing settings on view appear
- [ ] Add proper error messages for all validation cases

### Phase 6: Share Extension - UI
- [ ] Create `ShareViewController.swift`
- [ ] Design form UI with all fields (Title, Description, Keywords, toggles)
- [ ] Extract URL from share input (NSExtensionItem)
- [ ] Extract page title from share input (if available)
- [ ] Pre-fill title field with page title
- [ ] Load default toggle values from UserDefaults
- [ ] Implement Cancel button (dismiss extension)
- [ ] Create state management for editing/saving/success/error states

### Phase 7: Share Extension - Save Flow
- [ ] Check if credentials exist in Keychain
  - If not, show "Server Not Configured" error
- [ ] Validate URL is present
  - If not, show "Invalid Input" error
- [ ] Show saving spinner
- [ ] Call Shiori login API
  - Handle auth errors
  - Handle network errors
- [ ] Parse keywords into tags array
- [ ] Call add bookmark API
  - Handle server errors
  - Handle network errors
- [ ] Show success message and auto-close after 1.5s
- [ ] Implement retry logic for retryable errors

### Phase 8: Share Extension - Error Handling
- [ ] Create error enum with all error types
- [ ] Implement error views for each error state
- [ ] Add retry functionality for network/server errors
- [ ] Add proper error messages with user-friendly text
- [ ] Test all error scenarios

### Phase 9: Testing & Polish (iOS/iPadOS)
- [ ] Test with real Shiori server instance
- [ ] Test all error scenarios
- [ ] Test on physical iOS device
- [ ] Test on iPad (different screen sizes)
- [ ] Verify share extension appears in Safari
- [ ] Test with missing/invalid credentials
- [ ] Test network failure scenarios
- [ ] Add app icon
- [ ] Polish UI spacing and fonts
- [ ] Add loading states

### Phase 10: macOS Support (Optional)
- [ ] Add macOS target to main app
- [ ] Adapt UI for macOS window sizing
- [ ] Add macOS Share Extension target
- [ ] Test share extension in Safari on Mac
- [ ] Test keyboard navigation
- [ ] Adapt UI for larger screens

---

## Code Structure

```
ShioriShare/
├── Shared/
│   ├── Models/
│   │   ├── Bookmark.swift
│   │   └── ShioriError.swift
│   ├── API/
│   │   └── ShioriAPI.swift
│   ├── Utilities/
│   │   ├── KeychainHelper.swift
│   │   └── SettingsManager.swift
│   └── Views/
│       ├── InstructionsView.swift
│       └── SettingsView.swift
├── iOS/
│   ├── ShioriShareApp.swift
│   └── Info.plist
├── macOS/
│   ├── ShioriShareApp.swift
│   └── Info.plist
├── ShareExtension/
│   ├── ShareViewController.swift
│   ├── BookmarkFormView.swift
│   ├── ErrorView.swift
│   └── Info.plist
└── Resources/
    ├── Assets.xcassets
    └── App Icons
```

---

## Key Implementation Notes

### Keychain Helper

```swift
class KeychainHelper {
    static let shared = KeychainHelper()
    private let accessGroup = "net.emberson.shiorishare.shared"
    
    func save(_ value: String, for key: String) throws
    func read(_ key: String) throws -> String?
    func delete(_ key: String) throws
}
```

### Settings Manager

```swift
class SettingsManager {
    static let shared = SettingsManager()
    private let userDefaults = UserDefaults(suiteName: "group.net.emberson.shiorishare")
    
    var defaultCreateArchive: Bool { get set }
    var defaultMakePublic: Bool { get set }
}
```

### Shiori API Client

```swift
class ShioriAPI {
    func login(serverURL: String, username: String, password: String) async throws -> String
    func addBookmark(serverURL: String, sessionID: String, url: String, title: String?, 
                     excerpt: String?, tags: [String], createArchive: Bool, 
                     isPublic: Bool) async throws -> Bookmark
}
```

### Share Extension State

```swift
enum ShareExtensionState {
    case editing
    case saving
    case success
    case error(ShareError)
}

enum ShareError: Error {
    case notConfigured
    case invalidURL
    case authenticationFailed
    case connectionFailed
    case serverError(code: Int)
    case unknown(message: String)
}
```

---

## Testing Checklist

### Main App
- [ ] Settings save to Keychain successfully
- [ ] Settings load from Keychain on app launch
- [ ] URL validation works correctly
- [ ] Test Connection successfully validates credentials
- [ ] Test Connection shows appropriate errors
- [ ] Default toggles save to UserDefaults

### Share Extension
- [ ] Share extension appears in Safari share sheet
- [ ] URL is correctly extracted from share
- [ ] Page title is correctly extracted (when available)
- [ ] Form validates required fields
- [ ] Keywords parse correctly into tags array
- [ ] Login succeeds with valid credentials
- [ ] Login fails appropriately with invalid credentials
- [ ] Bookmark saves successfully
- [ ] Success message shows and auto-closes
- [ ] All error states display correctly
- [ ] Retry works for retryable errors
- [ ] Cancel button closes extension

### Cross-Platform
- [ ] Keychain sharing works between app and extension
- [ ] App Group UserDefaults sharing works
- [ ] Works on iPhone (various sizes)
- [ ] Works on iPad
- [ ] (Optional) Works on macOS

---

## Future Enhancements (Post-MVP)

- [ ] Session caching (store session ID temporarily to avoid re-login)
- [ ] Bookmark history/queue (save failed bookmarks for retry)
- [ ] Tag suggestions based on previous bookmarks
- [ ] Migration to Shiori API v1 when stable
- [ ] macOS menu bar integration
- [ ] Keyboard shortcuts
- [ ] Dark mode optimization
- [ ] Localization/internationalization

---

## Resources

- Shiori GitHub: https://github.com/go-shiori/shiori
- Shiori API Docs (Old): https://github.com/go-shiori/shiori/blob/master/docs/API.md
- Shiori API Docs (v1): https://github.com/go-shiori/shiori/blob/master/docs/APIv1.md
- Apple Share Extension: https://developer.apple.com/documentation/uikit/share_extension
- Keychain Services: https://developer.apple.com/documentation/security/keychain_services
- App Groups: https://developer.apple.com/documentation/xcode/configuring-app-groups

---

## Notes

- Start with iOS/iPadOS development first
- Add macOS support after iOS is stable
- Use SwiftUI for all UI components
- Use async/await for API calls
- Prioritize error handling and user feedback
- Keep UI simple and focused on core functionality
