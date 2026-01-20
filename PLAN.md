# Shiori Share - Development Plan

## Project Overview

**App Name**: Shiori Share  
**Purpose**: iOS/iPadOS/macOS app to save bookmarks from Safari (and other apps) to a Shiori bookmark manager server via the share sheet.

**Bundle IDs**:
- Main App: `net.emberson.shiorishare`
- Share Extension: `net.emberson.shiorishare.ShareExtension`
- App Group: `group.net.emberson.shiorishare`
- Keychain Access Group: `$(TeamIdentifierPrefix)net.emberson.shiorishare.shared`

**Target Platforms**:
- iOS 15.0+
- iPadOS 15.0+
- macOS 12.0+ (Monterey)

**Recommendation**: Start with iOS/iPadOS, then add macOS support.

### Platform Considerations

**App Transport Security (ATS)**:
- By default, iOS requires HTTPS connections
- If users need HTTP support (local dev servers, self-hosted without TLS):
  - Add `NSAppTransportSecurity` exception in Info.plist
  - Consider `NSAllowsLocalNetworking` for local network access
  - Document security implications to users

**Privacy Manifest (iOS 17+)**:
- Keychain access requires declaration in `PrivacyInfo.xcprivacy`
- Required API types to declare:
  - `NSPrivacyAccessedAPICategoryUserDefaults` (for App Group defaults)
- Add privacy manifest to both main app and Share Extension targets

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

### Share Extension Constraints

Share Extensions have strict limitations that must be considered:

- **Memory limit**: ~120MB on iOS. Keep dependencies minimal.
- **No background execution**: Use `beginBackgroundTask` for network requests to avoid termination mid-save.
- **Limited API access**: Some iOS APIs are unavailable in extensions.
- **SwiftUI hosting**: Share Extensions expect a `UIViewController`. Embed SwiftUI views via `UIHostingController`.

---

## Data Storage

### Keychain (Shared via Keychain Access Group)
- Key: `shiori.serverURL` → Value: "https://shiori.example.com"
- Key: `shiori.username` → Value: "username"
- Key: `shiori.password` → Value: "password"

### UserDefaults (Shared via App Group)
- Key: `defaultCreateArchive` → Value: Bool (default: true)
- Key: `defaultMakePublic` → Value: Bool (default: false)
- Key: `recentTags` → Value: [String] (most recent tags used, max 10)

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

**Response** (on success):
```json
{
  "id": 123,
  "url": "https://example.com/article",
  "title": "Article Title",
  "excerpt": "Description text here",
  ...
}
```

**Important Notes**:
- `public` field uses integers: `1` for public, `0` for private (not boolean)
- `tags` must be array of objects with "name" key: `[{"name": "tag1"}]`
- Shiori may ignore provided title and fetch automatically
- `excerpt` maps to our "description" field
- **Capture the `id` from response** to construct "Open in Shiori" URL: `{serverURL}/bookmark/{id}`

### Session Caching Strategy

To avoid re-authenticating on every bookmark save:

1. After successful login, cache the session ID in App Group UserDefaults with a timestamp
2. Use a short TTL (5-10 minutes) since Share Extensions are short-lived
3. On save attempt:
   - Check if cached session exists and is not expired
   - If valid, use cached session; if API returns 401, clear cache and re-login
   - If expired or missing, perform fresh login
4. Clear cached session when credentials change in Settings

**Storage**:
- Key: `cachedSessionID` → Value: String
- Key: `sessionTimestamp` → Value: Date

### URL Extraction from Share Sheet

Different apps provide URLs differently via `NSExtensionItem`. Handle multiple `NSItemProvider` types:

| Type Identifier | Source | Extraction Method |
|-----------------|--------|-------------------|
| `public.url` | Safari, most apps | Direct URL |
| `public.plain-text` | Some apps | Parse text for URL |
| `public.html` | Rich text shares | Extract from content |

**Priority order**: Try `public.url` first, fall back to `public.plain-text`.

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
│  💡 Tip                          │
│                                 │
│  To move Shiori Share higher    │
│  in the share sheet, scroll     │
│  right and tap "More", then     │
│  tap "Edit" to reorder.         │
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
│  │ •••••••••••••        [👁] │ │
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
- Password field with show/hide toggle (eye icon)
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
│  [tech] [article] [tutorial]   │  ← Recent tags
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
  - Recent tags shown as tappable chips below the field
  - Tapping a chip appends it to the keywords field
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
│         ✓                       │
│                                 │
│  Bookmark saved successfully!   │
│                                 │
│   [Done]    [Open in Shiori]    │
│                                 │
└─────────────────────────────────┘
```

**Behavior**:
- "Done" closes the extension immediately
- "Open in Shiori" opens `{serverURL}/bookmark/{bookmarkID}` in Safari, then closes
- Haptic feedback (success) plays when this screen appears

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

## Edge Cases & Special Handling

### Duplicate Bookmarks
- Shiori may return an error if the URL already exists
- Handle gracefully: show "Bookmark already saved" message (not an error)
- Consider this a success case from UX perspective

### Empty Title
- If no title is extracted from the share:
  - Show placeholder text: "Enter a title..."
  - Do not make title required (Shiori will fetch it)
  - Focus the title field to encourage input

### URL Normalization
- Strip trailing slashes from server URL in Settings
- Auto-add `https://` if user omits scheme
- Validate URL format before saving

### Concurrent Save Prevention
- Disable Save button immediately when tapped
- Show loading indicator
- Re-enable only on error with Retry option

### Extension Lifecycle
- iOS may terminate extension mid-save
- Use `ProcessInfo.processInfo.performExpiringActivity` or `beginBackgroundTask`
- Keep network requests as fast as possible

### Long URLs/Titles
- Truncate display of very long URLs in the form
- Allow full title editing regardless of length
- Let Shiori handle any length limits server-side

### Haptic Feedback (iOS)
- **Success**: Play `.success` notification feedback when bookmark saves successfully
- **Error**: Play `.error` notification feedback when save fails
- Use `UINotificationFeedbackGenerator` for these patterns
- No haptics on macOS (not supported)

---

## Accessibility

### VoiceOver Support
- All interactive elements must have meaningful accessibility labels
- Form fields: "Server URL, text field", "Password, secure text field"
- Buttons: "Save bookmark", "Test connection", "Cancel"
- State announcements: "Saving bookmark", "Bookmark saved successfully"

### Dynamic Type
- All text must scale with system font size settings
- Use `@ScaledMetric` for custom spacing that should scale
- Test with largest accessibility text sizes

### Color & Contrast
- Ensure WCAG AA compliance for text contrast
- Don't rely solely on color to convey information
- Error states should use icons + text, not just red color

### Keyboard Navigation (macOS)
- All controls reachable via Tab key
- Clear focus indicators
- Support standard keyboard shortcuts (Cmd+S for Save, Esc for Cancel)

---

## Development Phases

### Phase 1: Project Setup
- [ ] Create multiplatform Xcode project (iOS + macOS)
- [ ] Configure Bundle IDs
- [ ] Add Share Extension target
- [ ] Enable App Groups capability for both targets
  - Group ID: `group.net.emberson.shiorishare`
- [ ] Enable Keychain Sharing capability for both targets
  - Access Group: `$(TeamIdentifierPrefix)net.emberson.shiorishare.shared`
- [ ] Set minimum deployment targets (iOS 15.0, macOS 12.0)
- [ ] Set up project structure with Shared folder
- [ ] Add Privacy Manifest (`PrivacyInfo.xcprivacy`) to both targets
- [ ] Configure ATS exception for local network (optional, in Info.plist)
- [ ] Create `AppConstants.swift` with all shared constants

### Phase 2: Keychain Helper & Storage
- [ ] Create `KeychainHelper.swift` utility class
- [ ] Implement save/read/delete methods for credentials
- [ ] Add error handling for Keychain operations
- [ ] Test Keychain access from both main app and extension
- [ ] Create `SettingsManager.swift` for UserDefaults access
- [ ] Create `String+URL.swift` with URL validation extensions
- [ ] Create `URLExtractor.swift` for share sheet URL extraction
  - Handle `public.url`, `public.plain-text` providers
  - Add fallback logic for different app sources

### Phase 3: Shiori API Client
- [ ] Create `ShioriAPI.swift` client
- [ ] Implement login method (`POST /api/login`)
- [ ] Implement add bookmark method (`POST /api/bookmarks`)
- [ ] Add proper error handling and typed errors
- [ ] Parse keywords into tags array format
- [ ] Handle public field as integer (0/1)
- [ ] Create `SessionManager.swift` for session caching
  - Cache session ID with timestamp in App Group UserDefaults
  - Implement TTL check (5-10 minutes)
  - Auto-refresh on 401 response
- [ ] Add unit tests for API client
- [ ] **Test API integration manually** before building UI

### Phase 4: Main App - Instructions Screen
- [ ] Create `InstructionsView.swift`
- [ ] Add welcome text and app description
- [ ] Add step-by-step usage instructions
- [ ] Add "Tip" section about reordering share sheet
- [ ] Add "About Shiori" section with link
- [ ] Add navigation bar with gear icon
- [ ] Navigation to Settings screen

### Phase 5: Main App - Settings Screen
- [ ] Create `SettingsView.swift`
- [ ] Add form with server URL, username, password fields
- [ ] Add password visibility toggle (eye icon)
- [ ] Add URL normalization (auto-add https://, strip trailing slash)
- [ ] Add validation for URL format (must start with http/https)
- [ ] Add Create Archive and Make Public toggles
- [ ] Implement "Save" button
  - Save credentials to Keychain
  - Clear cached session when credentials change
  - Save defaults to UserDefaults
  - Show success/error message
- [ ] Implement "Test Connection" button
  - Call Shiori login API
  - Show success/error message
- [ ] Load existing settings on view appear
- [ ] Add proper error messages for all validation cases
- [ ] Add accessibility labels to all form elements

### Phase 6: Share Extension - UI
- [ ] Create `ShareViewController.swift` (UIViewController subclass)
- [ ] Set up `UIHostingController` to embed SwiftUI views
- [ ] Create `ShareExtensionView.swift` (main SwiftUI view)
- [ ] Design form UI with all fields (Title, Description, Keywords, toggles)
- [ ] Use `URLExtractor` to extract URL from share input
- [ ] Extract page title from share input (if available)
- [ ] Pre-fill title field with page title (or show placeholder if empty)
- [ ] Load default toggle values from UserDefaults
- [ ] Add recent tags as tappable chips below Keywords field
  - Load from `recentTags` in UserDefaults
  - Tapping chip appends tag to Keywords field
- [ ] Implement Cancel button (dismiss extension)
- [ ] Implement Save button with disabled state during save
- [ ] Create state management for editing/saving/success/error states
- [ ] Add accessibility labels to all form elements

### Phase 7: Share Extension - Save Flow
- [ ] Check if credentials exist in Keychain
  - If not, show "Server Not Configured" error
- [ ] Validate URL is present
  - If not, show "Invalid Input" error
- [ ] Disable Save button and show saving spinner
- [ ] Use `beginBackgroundTask` to prevent termination during save
- [ ] Use `SessionManager` for login (cached or fresh)
  - Handle auth errors
  - Handle network errors
- [ ] Parse keywords into tags array
- [ ] Call add bookmark API
  - **Capture bookmark ID from response**
  - Handle server errors
  - Handle network errors
  - Handle duplicate bookmark (treat as success)
- [ ] Update `recentTags` in UserDefaults with newly used tags
- [ ] Play haptic feedback (success or error)
- [ ] Show success screen with "Done" and "Open in Shiori" buttons
  - "Open in Shiori" uses `extensionContext?.open()` with `{serverURL}/bookmark/{id}`
- [ ] Implement retry logic for retryable errors
- [ ] End background task on completion

### Phase 8: Share Extension - Error Handling
- [ ] Create error enum with all error types
- [ ] Implement error views for each error state
- [ ] Add retry functionality for network/server errors
- [ ] Add proper error messages with user-friendly text
- [ ] Handle "bookmark already exists" as success case

### Phase 9: Integration Smoke Test
- [ ] Verify happy path end-to-end with real Shiori server
- [ ] Test: Configure server in app → Share from Safari → Save bookmark
- [ ] Verify bookmark appears in Shiori
- [ ] Fix any integration issues before polishing

### Phase 10: Testing & Polish (iOS/iPadOS)
- [ ] Test all error scenarios comprehensively
- [ ] Test on physical iOS device
- [ ] Test on iPad (different screen sizes)
- [ ] Verify share extension appears in Safari
- [ ] Test with missing/invalid credentials
- [ ] Test network failure scenarios
- [ ] Test session caching (save multiple bookmarks quickly)
- [ ] Test VoiceOver accessibility
- [ ] Test Dynamic Type scaling
- [ ] Add app icon
- [ ] Polish UI spacing and fonts

### Phase 11: macOS Support (Optional)
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
│   │   ├── ShioriAPI.swift
│   │   └── SessionManager.swift        # Session caching logic
│   ├── Utilities/
│   │   ├── KeychainHelper.swift
│   │   ├── SettingsManager.swift
│   │   └── URLExtractor.swift          # Share sheet URL extraction
│   ├── Extensions/
│   │   └── String+URL.swift            # URL validation helpers
│   ├── Constants/
│   │   └── AppConstants.swift          # Keychain keys, app group ID, etc.
│   └── Views/
│       ├── InstructionsView.swift
│       └── SettingsView.swift
├── App/
│   ├── ShioriShareApp.swift            # Shared app entry point
│   ├── Info.plist
│   └── PrivacyInfo.xcprivacy           # Privacy manifest
├── ShareExtension/
│   ├── ShareViewController.swift       # UIViewController hosting SwiftUI
│   ├── ShareExtensionView.swift        # Main SwiftUI view
│   ├── BookmarkFormView.swift
│   ├── StatusViews.swift               # Loading, success, error views
│   ├── Info.plist
│   └── PrivacyInfo.xcprivacy           # Privacy manifest for extension
└── Resources/
    ├── Assets.xcassets
    └── Localizable.strings             # For future i18n
```

---

## Key Implementation Notes

### Bookmark Model

```swift
struct Bookmark: Codable {
    let id: Int
    let url: String
    let title: String
    let excerpt: String?
    let author: String?
    let public: Int        // 0 = private, 1 = public
    let createdAt: String?
    let modifiedAt: String?
    let tags: [Tag]?

    struct Tag: Codable {
        let name: String
    }

    /// URL to view/edit this bookmark in Shiori web interface
    func webURL(serverURL: String) -> URL? {
        URL(string: "\(serverURL)/bookmark/\(id)")
    }
}
```

### Keychain Helper

```swift
class KeychainHelper {
    static let shared = KeychainHelper()
    // Note: Team ID prefix is added automatically by the system
    private let accessGroup = "$(TeamIdentifierPrefix)net.emberson.shiorishare.shared"

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

    // Session caching
    var cachedSessionID: String? { get set }
    var sessionTimestamp: Date? { get set }

    // Recent tags (max 10, most recent first)
    var recentTags: [String] { get set }

    func addRecentTags(_ tags: [String]) {
        var current = recentTags
        for tag in tags {
            current.removeAll { $0 == tag }
            current.insert(tag, at: 0)
        }
        recentTags = Array(current.prefix(10))
    }
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

### Session Manager

```swift
class SessionManager {
    static let shared = SessionManager()
    private let settings = SettingsManager.shared
    private let api = ShioriAPI()
    private let sessionTTL: TimeInterval = 300 // 5 minutes

    /// Returns a valid session ID, using cached value if available
    func getValidSession() async throws -> String {
        if let cached = settings.cachedSessionID,
           let timestamp = settings.sessionTimestamp,
           Date().timeIntervalSince(timestamp) < sessionTTL {
            return cached
        }
        return try await refreshSession()
    }

    func refreshSession() async throws -> String {
        // Load credentials from Keychain and login
        // Cache new session and timestamp
    }

    func clearSession() {
        settings.cachedSessionID = nil
        settings.sessionTimestamp = nil
    }
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
    case duplicateBookmark        // Treat as success in UI
    case unknown(message: String)
}
```

### URL Extractor

```swift
class URLExtractor {
    /// Extracts URL from NSExtensionItem attachments
    static func extractURL(from extensionItems: [NSExtensionItem]) async -> URL? {
        for item in extensionItems {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                // Try public.url first (most reliable)
                if provider.hasItemConformingToTypeIdentifier("public.url") {
                    if let url = try? await provider.loadItem(forTypeIdentifier: "public.url") as? URL {
                        return url
                    }
                }
                // Fall back to plain text and parse for URL
                if provider.hasItemConformingToTypeIdentifier("public.plain-text") {
                    if let text = try? await provider.loadItem(forTypeIdentifier: "public.plain-text") as? String,
                       let url = URL(string: text), url.scheme != nil {
                        return url
                    }
                }
            }
        }
        return nil
    }
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

- [ ] **Offline Queue**: When save fails due to network issues, queue the bookmark locally. Show pending bookmarks in main app with retry option. Sync automatically when network returns.
- [ ] Migration to Shiori API v1 when stable
- [ ] macOS menu bar integration
- [ ] Keyboard shortcuts
- [ ] Dark mode optimization
- [ ] Localization/internationalization
- [ ] Siri Shortcuts integration ("Save this page to Shiori")
- [ ] Widget showing recent bookmarks or quick-add action

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
