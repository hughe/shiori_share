import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var serverURL: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    
    @State private var createArchive: Bool = true
    @State private var makePublic: Bool = false
    
    @State private var trustSelfSignedCerts: Bool = false
    @State private var debugLoggingEnabled: Bool = false
    
    @State private var statusMessage: String = ""
    @State private var isError: Bool = false
    @State private var isTesting: Bool = false
    @State private var isSaving: Bool = false
    
    private let keychain = KeychainHelper.shared
    private let settings = SettingsManager.shared
    
    var body: some View {
        #if os(macOS)
        VStack(alignment: .leading, spacing: 20) {
            serverConfigurationSection
            defaultSettingsSection
            advancedSection
            actionsSection
            statusSection
                .opacity(statusMessage.isEmpty ? 0 : 1)
        }
        .padding()
        .frame(width: 400)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveSettings()
                }
                .disabled(isSaving || !isFormValid)
            }
        }
        .onAppear(perform: loadSettings)
        #else
        NavigationView {
            Form {
                serverConfigurationSection
                defaultSettingsSection
                advancedSection
                actionsSection
                
                if !statusMessage.isEmpty {
                    statusSection
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSettings()
                    }
                    .disabled(isSaving || !isFormValid)
                }
            }
            .onAppear(perform: loadSettings)
        }
        .navigationViewStyle(.stack)
        #endif
    }
    
    // MARK: - Sections
    
    private var serverConfigurationSection: some View {
        Section {
            TextField("Server URL", text: $serverURL)
                #if os(iOS)
                .textContentType(.URL)
                .keyboardType(.URL)
                .autocapitalization(.none)
                #endif
                .disableAutocorrection(true)
                .accessibilityHint("Enter your Shiori server URL, for example https://shiori.example.com")
            
            TextField("Username", text: $username)
                #if os(iOS)
                .textContentType(.username)
                .autocapitalization(.none)
                #endif
                .disableAutocorrection(true)
                .accessibilityHint("Enter your Shiori username")
            
            HStack {
                if showPassword {
                    TextField("Password", text: $password)
                        #if os(iOS)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        #endif
                        .disableAutocorrection(true)
                } else {
                    SecureField("Password", text: $password)
                        #if os(iOS)
                        .textContentType(.password)
                        #endif
                }
                
                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showPassword ? "Hide password" : "Show password")
            }
        } header: {
            Text("Server Configuration")
        }
    }
    
    private var defaultSettingsSection: some View {
        Section {
            Toggle("Create Archive", isOn: $createArchive)
                .accessibilityHint("When enabled, Shiori will save an offline copy of the page")
            Toggle("Make Public", isOn: $makePublic)
                .accessibilityHint("When enabled, bookmarks will be publicly visible")
        } header: {
            Text("Default Settings")
        }
    }
    
    private var advancedSection: some View {
        Section {
            Toggle(isOn: $trustSelfSignedCerts) {
                HStack {
                    Text("Trust Self-Signed Certs")
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityHint("Enable this only for servers with self-signed certificates that you trust")
            
            if trustSelfSignedCerts {
                Text("Only enable this for servers you trust.")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            Toggle("Enable Debug Logging", isOn: $debugLoggingEnabled)
                .accessibilityHint("When enabled, saves detailed logs for troubleshooting")
        } header: {
            Text("Advanced")
        }
    }
    
    private var actionsSection: some View {
        Section {
            Button {
                testConnection()
            } label: {
                HStack {
                    if isTesting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text("Test Connection")
                }
            }
            .disabled(isTesting || !isFormValid)
        }
    }
    
    private var statusSection: some View {
        Section {
            HStack {
                Image(systemName: isError ? "exclamationmark.triangle" : "checkmark.circle")
                    .foregroundColor(isError ? .orange : .green)
                Text(statusMessage)
                    .font(.callout)
            }
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !serverURL.trimmingCharacters(in: .whitespaces).isEmpty &&
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty &&
        serverURL.normalizedServerURL.isValidHTTPURL
    }
    
    // MARK: - Actions
    
    private func loadSettings() {
        serverURL = keychain.serverURL ?? ""
        username = keychain.username ?? ""
        password = keychain.password ?? ""
        
        createArchive = settings.defaultCreateArchive
        makePublic = settings.defaultMakePublic
        trustSelfSignedCerts = settings.trustSelfSignedCerts
        debugLoggingEnabled = settings.debugLoggingEnabled
    }
    
    private func saveSettings() {
        isSaving = true
        statusMessage = ""
        
        let normalizedURL = serverURL.normalizedServerURL
        
        keychain.serverURL = normalizedURL
        keychain.username = username
        keychain.password = password
        
        settings.defaultCreateArchive = createArchive
        settings.defaultMakePublic = makePublic
        settings.trustSelfSignedCerts = trustSelfSignedCerts
        settings.debugLoggingEnabled = debugLoggingEnabled
        
        DebugLogger.shared.info("Settings saved")
        
        isSaving = false
        dismiss()
    }
    
    private func testConnection() {
        isTesting = true
        statusMessage = ""
        
        let normalizedURL = serverURL.normalizedServerURL
        
        guard let url = URL(string: normalizedURL) else {
            statusMessage = "Invalid server URL"
            isError = true
            isTesting = false
            return
        }
        
        let loginURL = url.appendingPathSafely(AppConstants.API.loginPath)
        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = AppConstants.Timing.networkTimeout
        
        let body: [String: Any] = [
            "username": username,
            "password": password,
            "remember": false
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            statusMessage = "Failed to create request"
            isError = true
            isTesting = false
            return
        }
        
        let session = createURLSession()
        
        DebugLogger.shared.apiRequest(method: "POST", url: loginURL.absoluteString)
        let startTime = Date()
        
        session.dataTask(with: request) { [self] data, response, error in
            let duration = Date().timeIntervalSince(startTime)
            
            DispatchQueue.main.async {
                isTesting = false
                
                if let error = error {
                    handleConnectionError(error)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    statusMessage = "Invalid server response"
                    isError = true
                    return
                }
                
                DebugLogger.shared.apiResponse(method: "POST", url: loginURL.absoluteString, statusCode: httpResponse.statusCode, duration: duration)
                
                switch httpResponse.statusCode {
                case 200:
                    statusMessage = "Connection successful!"
                    isError = false
                case 401, 403:
                    statusMessage = "Authentication failed. Check username and password."
                    isError = true
                case 404:
                    statusMessage = "Shiori API not found at this URL. Check the server URL."
                    isError = true
                case 500...599:
                    statusMessage = "Server error. Shiori may be experiencing issues."
                    isError = true
                default:
                    statusMessage = "Unexpected response: \(httpResponse.statusCode)"
                    isError = true
                }
            }
        }.resume()
    }
    
    private func handleConnectionError(_ error: Error) {
        let nsError = error as NSError
        
        switch nsError.code {
        case NSURLErrorCannotFindHost:
            statusMessage = "Could not find server. Check the URL is correct."
        case NSURLErrorCannotConnectToHost:
            statusMessage = "Server not responding. Is Shiori running?"
        case NSURLErrorTimedOut:
            statusMessage = "Connection timed out. Server may be slow or unreachable."
        case NSURLErrorServerCertificateUntrusted, NSURLErrorSecureConnectionFailed:
            statusMessage = "Certificate error. Enable 'Trust Self-Signed Certs' if using self-signed certificate."
        default:
            statusMessage = "Connection failed: \(error.localizedDescription)"
        }
        isError = true
    }
    
    private func createURLSession() -> URLSession {
        if trustSelfSignedCerts {
            let config = URLSessionConfiguration.default
            return URLSession(configuration: config, delegate: TrustingSessionDelegate(), delegateQueue: nil)
        }
        return URLSession.shared
    }
}

private class TrustingSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

#Preview {
    SettingsView()
}
