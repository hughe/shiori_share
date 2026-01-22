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
- iOS 18.0+
- iPadOS 18.0+
- macOS 15.0+ (Sequoia)

**Recommendation**: Start with iOS/iPadOS, then add macOS support.

### Platform Considerations

**App Transport Security (ATS)**:
- By default, iOS requires HTTPS connections
- If users need HTTP support (local dev servers, self-hosted without TLS):
  - Add `NSAppTransportSecurity` exception in Info.plist
  - Consider `NSAllowsLocalNetworking` for local network access
  - Document security implications to users

**Self-Signed Certificate Support**:
- Many self-hosted Shiori users have self-signed certificates
- Add "Trust Self-Signed Certificates" toggle in Settings (off by default)
- Show warning when enabled: "Only enable this for servers you trust"
- Implement custom `URLSessionDelegate` to handle certificate validation
- When disabled, show helpful error message if cert validation fails

**Privacy Manifest (iOS 17+)**:
- Keychain access requires declaration in `PrivacyInfo.xcprivacy`
- Required API types to declare:
  - `NSPrivacyAccessedAPICategoryUserDefaults` (for App Group defaults)
- Add privacy manifest to both main app and Share Extension targets

---

## Configuration Reference

> **Single source of truth for all identifiers and settings.**
> Copy these exactly - typos in identifiers cause silent failures.

### Bundle Identifiers
| Target | Bundle ID |
|--------|-----------|
| Main App | `net.emberson.shiorishare` |
| Share Extension | `net.emberson.shiorishare.ShareExtension` |

### Shared Access Groups
| Type | Identifier | Used For |
|------|------------|----------|
| App Group | `group.net.emberson.shiorishare` | UserDefaults, Debug Logs |
| Keychain | `$(TeamIdentifierPrefix)net.emberson.shiorishare.shared` | Credentials |

### Keychain Keys
| Key | Type | Description |
|-----|------|-------------|
| `shiori.serverURL` | String | Server base URL |
| `shiori.username` | String | Login username |
| `shiori.password` | String | Login password |

### UserDefaults Keys (App Group)
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `defaultCreateArchive` | Bool | `true` | Create archive by default |
| `defaultMakePublic` | Bool | `false` | Make bookmarks public by default |
| `recentTags` | [String] | `[]` | Recently used tags (max 10) |
| `trustSelfSignedCerts` | Bool | `false` | Allow self-signed SSL certs |
| `debugLoggingEnabled` | Bool | `false` | Enable debug logging |
| `cachedSessionID` | String? | `nil` | Cached API session |
| `sessionTimestamp` | Date? | `nil` | When session was cached |

### Xcode Capabilities (Both Targets)
1. **App Groups**: Add `group.net.emberson.shiorishare`
2. **Keychain Sharing**: Add `$(TeamIdentifierPrefix)net.emberson.shiorishare.shared`

### Entitlements File Contents

**ShioriShare.entitlements** (Main App):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.net.emberson.shiorishare</string>
    </array>
    <key>keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix)net.emberson.shiorishare.shared</string>
    </array>
</dict>
</plist>
```

**ShareExtension.entitlements** (Share Extension):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.net.emberson.shiorishare</string>
    </array>
    <key>keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix)net.emberson.shiorishare.shared</string>
    </array>
</dict>
</plist>
```

### Info.plist - Share Extension

The Share Extension requires specific configuration to appear in the share sheet and accept URLs:

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>NSExtensionActivationRule</key>
        <dict>
            <!-- Activate for URLs -->
            <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
            <integer>1</integer>
            <!-- Also activate for plain text (may contain URL) -->
            <key>NSExtensionActivationSupportsText</key>
            <true/>
        </dict>
    </dict>
    <key>NSExtensionMainStoryboard</key>
    <string>MainInterface</string>
    <!-- Or if using programmatic UI: -->
    <!-- <key>NSExtensionPrincipalClass</key> -->
    <!-- <string>$(PRODUCT_MODULE_NAME).ShareViewController</string> -->
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.share-services</string>
</dict>
```

**Important**: During development, you can use `TRUEPREDICATE` for activation rule, but **App Store requires specific rules** (not TRUEPREDICATE).

### Info.plist - ATS Exception (Optional)

If you need to support HTTP or local network servers:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <!-- Allow local network connections (e.g., 192.168.x.x) -->
    <key>NSAllowsLocalNetworking</key>
    <true/>
    <!-- For specific HTTP domains (not recommended for production) -->
    <key>NSExceptionDomains</key>
    <dict>
        <key>example.local</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### Privacy Manifest (PrivacyInfo.xcprivacy)

Required for iOS 17+ App Store submission:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

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
- Key: `trustSelfSignedCerts` → Value: Bool (default: false)
- Key: `debugLoggingEnabled` → Value: Bool (default: false)

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
│  Advanced                       │
│                                 │
│  ☐ Trust Self-Signed Certs  ⚠️  │
│  ☐ Enable Debug Logging         │
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
- Two toggles for default preferences (Create Archive, Make Public)
- Advanced section:
  - Trust Self-Signed Certificates toggle (with warning icon/text)
  - Enable Debug Logging toggle
- "Test Connection" button with detailed diagnostics on failure
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

### Share Source Validation
Different apps share content differently. Handle gracefully:

| Share Source | Content Type | Handling |
|--------------|--------------|----------|
| Safari, Chrome, Firefox | `public.url` | Direct URL extraction |
| Some apps | `public.plain-text` | Parse text for URL pattern |
| Twitter/X, Reddit | Mixed | Try URL first, then parse text |
| Text selection | Plain text | Extract URL if present in text |
| Images, files | Non-URL | Show error: "No URL found" |

**Error message for non-URL content**:
```
┌─────────────────────────────────┐
│  Save to Shiori          [✕]   │
├─────────────────────────────────┤
│                                 │
│         ⚠️                       │
│                                 │
│  No URL Found                   │
│                                 │
│  The shared content doesn't     │
│  contain a URL. Try sharing     │
│  from a browser or app that     │
│  shares links.                  │
│                                 │
│           [OK]                  │
│                                 │
└─────────────────────────────────┘
```

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

### Debug Logging
When "Enable Debug Logging" is on in Settings:
- Log API requests (method, URL, headers excluding auth)
- Log API responses (status code, body preview)
- Log errors with full context
- Store logs in App Group container (`logs/` directory)
- Auto-delete logs older than 7 days
- Main app provides "Export Debug Log" button (shares as text file)
- **Never log passwords or full session tokens**

**Log format**:
```
[2024-01-15 10:30:45] INFO: POST /api/login -> 200 OK (145ms)
[2024-01-15 10:30:46] INFO: POST /api/bookmarks -> 201 Created (892ms)
[2024-01-15 10:30:46] INFO: Bookmark saved: id=123
[2024-01-15 10:31:02] ERROR: POST /api/bookmarks -> SSL certificate error
```

### Connection Diagnostics
"Test Connection" button should provide detailed failure information:

| Error Type | Diagnostic Message |
|------------|-------------------|
| DNS failure | "Could not find server. Check the URL is correct." |
| Connection refused | "Server not responding. Is Shiori running?" |
| Timeout | "Connection timed out. Server may be slow or unreachable." |
| SSL/TLS error | "Certificate error. Enable 'Trust Self-Signed Certs' if using self-signed certificate." |
| 401/403 | "Authentication failed. Check username and password." |
| 404 | "Shiori API not found at this URL. Check the server URL." |
| 5xx | "Server error. Shiori may be experiencing issues." |

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

### Complexity Legend
- **[S]** Small - Straightforward, < 30 mins
- **[M]** Medium - Some complexity, 30 mins - 2 hours
- **[L]** Large - Significant work, 2+ hours or requires research

### Phase Dependencies
```
Phase 1 ─────┬──→ Phase 2 ──→ Phase 3 ──┬──→ Phase 6 ──→ Phase 7 ──→ Phase 8 ──→ Phase 9
             │                          │
             └──→ Phase 4 ──────────────┤
             └──→ Phase 5 ──────────────┘
                  (4 & 5 can parallel with 2 & 3)
```

---

### Phase 1: Project Setup
- [ ] [S] Create multiplatform Xcode project (iOS + macOS)
- [ ] [S] Configure Bundle IDs (see Configuration Reference)
- [ ] [S] Add Share Extension target
- [ ] [M] Enable App Groups capability for both targets
  - Group ID: `group.net.emberson.shiorishare`
- [ ] [M] Enable Keychain Sharing capability for both targets
  - Access Group: `$(TeamIdentifierPrefix)net.emberson.shiorishare.shared`
- [ ] [S] Set minimum deployment targets (iOS 18.0, macOS 15.0)
- [ ] [S] Set up project structure with Shared folder
- [ ] [S] Add Privacy Manifest (`PrivacyInfo.xcprivacy`) to both targets
- [ ] [S] Configure ATS exception for local network (optional, in Info.plist)
- [ ] [S] Create `AppConstants.swift` with all shared constants

**✓ Verification**:
1. Project builds without errors for both iOS and macOS
2. Share Extension target appears in scheme selector
3. Both targets show App Groups and Keychain Sharing in Signing & Capabilities
4. Run on Simulator - main app launches (even if blank)

---

### Phase 2: Keychain Helper & Storage
- [ ] [M] Create `KeychainHelper.swift` utility class
- [ ] [M] Implement save/read/delete methods for credentials
- [ ] [S] Add error handling for Keychain operations
- [ ] [L] Test Keychain access from both main app and extension ⚠️ *Critical - do this before proceeding*
- [ ] [M] Create `SettingsManager.swift` for UserDefaults access
- [ ] [S] Create `String+URL.swift` with URL validation extensions
- [ ] [M] Create `URLExtractor.swift` for share sheet URL extraction
  - Handle `public.url`, `public.plain-text` providers
  - Add fallback logic for different app sources
  - Return nil for non-URL content (images, files, etc.)
- [ ] [M] Create `DebugLogger.swift` utility
  - Log to App Group container
  - Auto-cleanup logs older than 7 days
  - Respect `debugLoggingEnabled` setting

**✓ Verification**:
1. Write a test value to Keychain from main app
2. Read that value from Share Extension - **must succeed**
3. Write a test value to App Group UserDefaults from main app
4. Read that value from Share Extension - **must succeed**
5. If either fails, check Common Pitfalls section before proceeding

---

### Phase 3: Shiori API Client
- [ ] [M] Create `ShioriAPI.swift` client
- [ ] [M] Implement login method (`POST /api/login`)
- [ ] [M] Implement add bookmark method (`POST /api/bookmarks`)
- [ ] [M] Add proper error handling and typed errors
  - Create `ConnectionError` enum with detailed error types
  - Map URLError codes to user-friendly diagnostics
- [ ] [L] Implement self-signed certificate support
  - Custom `URLSessionDelegate` for certificate validation
  - Respect `trustSelfSignedCerts` setting
- [ ] [S] Parse keywords into tags array format
- [ ] [S] Handle public field as integer (0/1)
- [ ] [M] Create `SessionManager.swift` for session caching
  - Cache session ID with timestamp in App Group UserDefaults
  - Implement TTL check (5-10 minutes)
  - Auto-refresh on 401 response
- [ ] [S] Add debug logging to all API calls
- [ ] [M] Add unit tests for API client
- [ ] [M] **Test API integration manually** before building UI ⚠️ *Critical checkpoint*

**✓ Verification** (requires a running Shiori server):
1. Call login API with valid credentials → returns session ID
2. Call login API with invalid credentials → returns auth error
3. Call add bookmark API → bookmark appears in Shiori
4. Test with self-signed cert server (if available)
5. All unit tests pass

---

### Phase 4: Main App - Instructions Screen
*Can be developed in parallel with Phase 2 & 3*

- [ ] [M] Create `InstructionsView.swift`
- [ ] [S] Add welcome text and app description
- [ ] [S] Add step-by-step usage instructions
- [ ] [S] Add "Tip" section about reordering share sheet
- [ ] [S] Add "About Shiori" section with link
- [ ] [S] Add navigation bar with gear icon
- [ ] [S] Navigation to Settings screen

**✓ Verification**:
1. App launches and shows Instructions screen
2. Gear icon appears in navigation bar
3. Tapping gear navigates to Settings (can be placeholder)
4. All text is readable and properly formatted

---

### Phase 5: Main App - Settings Screen
*Can be developed in parallel with Phase 2 & 3*

- [ ] [M] Create `SettingsView.swift`
- [ ] [S] Add form with server URL, username, password fields
- [ ] [S] Add password visibility toggle (eye icon)
- [ ] [S] Add URL normalization (auto-add https://, strip trailing slash)
- [ ] [S] Add validation for URL format (must start with http/https)
- [ ] [S] Add Create Archive and Make Public toggles
- [ ] [M] Add Advanced section:
  - Trust Self-Signed Certificates toggle (with warning)
  - Enable Debug Logging toggle
  - Export Debug Log button (share sheet)
- [ ] [M] Implement "Save" button
  - Save credentials to Keychain
  - Clear cached session when credentials change
  - Save defaults to UserDefaults
  - Show success/error message
- [ ] [L] Implement "Test Connection" button
  - Call Shiori login API
  - Show detailed diagnostic messages on failure
  - Display specific error (DNS, timeout, SSL, auth, etc.)
- [ ] [S] Load existing settings on view appear
- [ ] [S] Add proper error messages for all validation cases
- [ ] [S] Add accessibility labels to all form elements

**✓ Verification**:
1. Can enter and save server URL, username, password
2. Settings persist after closing and reopening app
3. Test Connection works with valid Shiori server
4. Test Connection shows appropriate error for invalid URL/credentials
5. Toggle states persist correctly

---

### Phase 6: Share Extension - UI
*Requires Phase 2 (URLExtractor, SettingsManager) and Phase 3 (API client)*

- [ ] [M] Create `ShareViewController.swift` (UIViewController subclass)
- [ ] [M] Set up `UIHostingController` to embed SwiftUI views
- [ ] [L] Create `ShareExtensionView.swift` (main SwiftUI view)
- [ ] [M] Design form UI with all fields (Title, Description, Keywords, toggles)
- [ ] [M] Use `URLExtractor` to extract URL from share input
  - Handle various content types (see Share Source Validation)
  - Show "No URL Found" error for non-URL content
- [ ] [S] Extract page title from share input (if available)
- [ ] [S] Pre-fill title field with page title (or show placeholder if empty)
- [ ] [S] Load default toggle values from UserDefaults
- [ ] [M] Add recent tags as tappable chips below Keywords field
  - Load from `recentTags` in UserDefaults
  - Tapping chip appends tag to Keywords field
- [ ] [S] Implement Cancel button (dismiss extension)
- [ ] [S] Implement Save button with disabled state during save
- [ ] [M] Create state management for editing/saving/success/error states
- [ ] [S] Add accessibility labels to all form elements

**✓ Verification**:
1. Share from Safari → extension appears in share sheet
2. URL is displayed in the form
3. Page title is pre-filled (if available)
4. Cancel button dismisses the extension
5. Form fields are editable
6. Recent tags appear (if any exist in UserDefaults)

---

### Phase 7: Share Extension - Save Flow
- [ ] [S] Check if credentials exist in Keychain
  - If not, show "Server Not Configured" error
- [ ] [S] Validate URL is present
  - If not, show "Invalid Input" error
- [ ] [S] Disable Save button and show saving spinner
- [ ] [M] Use `beginBackgroundTask` to prevent termination during save
- [ ] [M] Use `SessionManager` for login (cached or fresh)
  - Handle auth errors
  - Handle network errors
- [ ] [S] Parse keywords into tags array
- [ ] [M] Call add bookmark API
  - **Capture bookmark ID from response**
  - Handle server errors
  - Handle network errors
  - Handle duplicate bookmark (treat as success)
- [ ] [S] Update `recentTags` in UserDefaults with newly used tags
- [ ] [S] Play haptic feedback (success or error)
- [ ] [M] Show success screen with "Done" and "Open in Shiori" buttons
  - "Open in Shiori" uses `extensionContext?.open()` with `{serverURL}/bookmark/{id}`
- [ ] [M] Implement retry logic for retryable errors
- [ ] [S] End background task on completion

**✓ Verification**:
1. Save bookmark → appears in Shiori server
2. "Done" button closes extension
3. "Open in Shiori" opens bookmark in Safari
4. Tags are saved to recent tags list
5. Haptic feedback triggers on success
6. Saving spinner appears while saving

---

### Phase 8: Share Extension - Error Handling
- [ ] [S] Create error enum with all error types
- [ ] [M] Implement error views for each error state
- [ ] [M] Add retry functionality for network/server errors
- [ ] [S] Add proper error messages with user-friendly text
- [ ] [S] Handle "bookmark already exists" as success case

**✓ Verification**:
1. No credentials configured → "Server Not Configured" error
2. Wrong credentials → "Authentication Failed" error
3. Server unreachable → "Connection Failed" with Retry button
4. Retry button works and re-attempts save

---

### Phase 9: Integration Smoke Test
⚠️ **Critical checkpoint before polish phase**

- [ ] [M] Verify happy path end-to-end with real Shiori server
- [ ] [M] Test: Configure server in app → Share from Safari → Save bookmark
- [ ] [S] Verify bookmark appears in Shiori
- [ ] [L] Fix any integration issues before polishing

**✓ Verification** (all must pass before proceeding):
1. Fresh install: Configure credentials in main app
2. Share a URL from Safari → extension opens
3. Fill in optional fields (description, tags)
4. Save → success screen appears
5. Tap "Open in Shiori" → Safari opens bookmark page
6. Verify bookmark exists in Shiori with correct data
7. Share another URL → recent tags appear from previous save

---

### Phase 10: Testing & Polish (iOS/iPadOS)
- [ ] [M] Test all error scenarios comprehensively
- [ ] [M] Test on physical iOS device
- [ ] [M] Test on iPad (different screen sizes)
- [ ] [S] Verify share extension appears in Safari
- [ ] [S] Test with missing/invalid credentials
- [ ] [M] Test network failure scenarios
- [ ] [S] Test session caching (save multiple bookmarks quickly)
- [ ] [M] Test VoiceOver accessibility
- [ ] [M] Test Dynamic Type scaling
- [ ] [M] Add app icon
- [ ] [M] Polish UI spacing and fonts

**✓ Verification**:
1. All items in Testing Checklist section pass
2. App works on physical device (not just Simulator)
3. No console warnings or errors during normal use
4. UI looks correct on smallest and largest iPhone sizes

---

### Phase 11: macOS Support (Optional)
- [ ] [M] Add macOS target to main app
- [ ] [M] Adapt UI for macOS window sizing
- [ ] [L] Add macOS Share Extension target
- [ ] [M] Test share extension in Safari on Mac
- [ ] [M] Test keyboard navigation
- [ ] [S] Adapt UI for larger screens

**✓ Verification**:
1. Main app runs on macOS with proper window sizing
2. Share extension appears in Safari share menu on Mac
3. Full keyboard navigation works (Tab, Enter, Escape)
4. Cmd+S saves, Escape cancels

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
│   │   ├── URLExtractor.swift          # Share sheet URL extraction
│   │   └── DebugLogger.swift           # Optional debug logging
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

    // Advanced settings
    var trustSelfSignedCerts: Bool { get set }
    var debugLoggingEnabled: Bool { get set }

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
    case noURLFound               // Shared content has no URL
    case invalidURL
    case authenticationFailed
    case connection(ConnectionError)
    case serverError(code: Int)
    case duplicateBookmark        // Treat as success in UI
    case unknown(message: String)
}

/// Detailed connection error for diagnostics
enum ConnectionError: Error {
    case dnsLookupFailed
    case connectionRefused
    case timeout
    case sslCertificateError(String)
    case noInternet
    case unknown(Error)

    var userMessage: String {
        switch self {
        case .dnsLookupFailed:
            return "Could not find server. Check the URL is correct."
        case .connectionRefused:
            return "Server not responding. Is Shiori running?"
        case .timeout:
            return "Connection timed out. Server may be slow or unreachable."
        case .sslCertificateError:
            return "Certificate error. Enable 'Trust Self-Signed Certs' if using self-signed certificate."
        case .noInternet:
            return "No internet connection."
        case .unknown:
            return "Connection failed. Check your network and try again."
        }
    }
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

### Debug Logger

```swift
class DebugLogger {
    static let shared = DebugLogger()
    private let settings = SettingsManager.shared
    private let logDirectory: URL  // App Group container/logs/

    func log(_ message: String, level: LogLevel = .info) {
        guard settings.debugLoggingEnabled else { return }
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let entry = "[\(timestamp)] \(level.rawValue): \(message)\n"
        appendToLog(entry)
    }

    func logAPIRequest(_ method: String, url: String) {
        log("\(method) \(url)")
    }

    func logAPIResponse(_ method: String, url: String, status: Int, duration: TimeInterval) {
        log("\(method) \(url) -> \(status) (\(Int(duration * 1000))ms)")
    }

    func logError(_ error: Error, context: String) {
        log("\(context): \(error.localizedDescription)", level: .error)
    }

    func exportLogs() -> URL?  // Returns file URL for sharing
    func clearOldLogs()        // Delete logs older than 7 days

    enum LogLevel: String {
        case info = "INFO"
        case error = "ERROR"
        case debug = "DEBUG"
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
- [ ] Test Connection shows detailed diagnostic errors:
  - [ ] DNS failure message
  - [ ] Connection refused message
  - [ ] Timeout message
  - [ ] SSL certificate error message
  - [ ] Authentication failed message
- [ ] Default toggles save to UserDefaults
- [ ] Self-signed certificate toggle works
- [ ] Debug logging toggle enables/disables logging
- [ ] Export Debug Log creates shareable file

### Share Extension
- [ ] Share extension appears in Safari share sheet
- [ ] URL is correctly extracted from share
- [ ] Page title is correctly extracted (when available)
- [ ] Sharing non-URL content shows "No URL Found" error
- [ ] Sharing from various apps works:
  - [ ] Safari
  - [ ] Chrome/Firefox
  - [ ] Twitter/X
  - [ ] Reddit
- [ ] Form validates required fields
- [ ] Recent tags appear as tappable chips
- [ ] Tapping tag chip adds it to Keywords field
- [ ] Keywords parse correctly into tags array
- [ ] Tags are saved to recent tags after successful save
- [ ] Login succeeds with valid credentials
- [ ] Login fails appropriately with invalid credentials
- [ ] Bookmark saves successfully
- [ ] Success screen shows Done and Open in Shiori buttons
- [ ] Open in Shiori opens correct URL in browser
- [ ] Haptic feedback plays on success/error
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

## Common Pitfalls & Troubleshooting

Issues you're likely to encounter, with solutions:

### Share Extension Not Appearing in Share Sheet

**Symptoms**: Extension doesn't show up when you tap Share in Safari.

**Solutions**:
1. **Check activation rules**: Ensure `NSExtensionActivationRule` in Info.plist is correct
2. **Check signing**: Both app and extension must be signed with same team
3. **Delete and reinstall**: iOS caches extension info; delete app completely and reinstall
4. **Check bundle ID**: Extension bundle ID must be prefixed with main app bundle ID
5. **Restart device**: Sometimes required after first install

### Keychain Access Fails in Extension

**Symptoms**: Credentials saved in main app return nil in Share Extension.

**Solutions**:
1. **Verify access group**: Must match exactly in both targets' entitlements
2. **Check `$(AppIdentifierPrefix)`**: This is your Team ID + dot (e.g., `ABC123XYZ.`)
3. **Provisioning profiles**: Regenerate profiles after adding Keychain Sharing capability
4. **Query attributes**: Use same `kSecAttrAccessGroup` when saving and reading

**Debug code**:
```swift
// Print your actual access group
let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword]
var result: AnyObject?
SecItemCopyMatching(query as CFDictionary, &result)
// Check Console.app for keychain errors
```

### App Group UserDefaults Returns Nil

**Symptoms**: Values saved in main app are nil in extension (or vice versa).

**Solutions**:
1. **Suite name must match**: `UserDefaults(suiteName: "group.net.emberson.shiorishare")`
2. **Call `synchronize()`**: Though usually unnecessary, try `userDefaults.synchronize()` after writing
3. **Check entitlements**: App Group must be in both targets' entitlements
4. **Verify in Xcode**: Signing & Capabilities → App Groups should show the group

### Extension Crashes on Launch

**Symptoms**: Share sheet briefly shows extension then dismisses.

**Solutions**:
1. **Check memory usage**: Extensions limited to ~120MB; avoid large frameworks
2. **Check Console.app**: Filter by your app name for crash logs
3. **Simplify initialization**: Move heavy work out of `viewDidLoad`
4. **Check for missing frameworks**: Ensure all linked frameworks are embedded

### "Could Not Connect" Despite Correct Credentials

**Symptoms**: Test Connection fails even though server is reachable in browser.

**Solutions**:
1. **ATS blocking HTTP**: Add ATS exception for HTTP URLs or local network
2. **Self-signed cert**: Enable "Trust Self-Signed Certificates" toggle
3. **Trailing slash**: Try both `https://shiori.example.com` and `https://shiori.example.com/`
4. **Port in URL**: Ensure port is included if non-standard: `https://shiori.example.com:8080`
5. **VPN/proxy**: iOS may route differently than browser; check network settings

### Extension Works in Simulator But Not Device

**Symptoms**: Everything works in Simulator, fails on real device.

**Solutions**:
1. **Provisioning profiles**: Device profiles must include App Groups and Keychain capabilities
2. **Device registered**: Ensure test device is in Apple Developer portal
3. **Clean build**: Product → Clean Build Folder, then rebuild
4. **Check device logs**: Window → Devices and Simulators → View Device Logs

### Session Token Expires Too Quickly

**Symptoms**: "Authentication failed" errors despite correct credentials.

**Solutions**:
1. **Check Shiori server settings**: Some servers have short session timeouts
2. **Clock sync**: Ensure device time is accurate (affects token validation)
3. **Clear cached session**: Force re-login by clearing `cachedSessionID`

### Bookmark Saves But Doesn't Appear in Shiori

**Symptoms**: Success shown but bookmark not in Shiori web UI.

**Solutions**:
1. **Check Shiori logs**: Server may have rejected with details
2. **Refresh Shiori UI**: Sometimes requires hard refresh
3. **Check API response**: Enable debug logging to see actual response
4. **Duplicate handling**: Shiori may silently skip duplicates

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
