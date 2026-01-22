import SwiftUI

#if os(macOS)
struct MacOSSectionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
    }
}

extension View {
    func macOSSectionStyle() -> some View {
        modifier(MacOSSectionStyle())
    }
}
#endif

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
    
    #if os(macOS)
    private enum Field: Int, CaseIterable {
        case serverURL, username, password, showPassword
        case createArchive, makePublic
        case trustSelfSignedCerts, debugLogging
        case testConnection
    }
    @FocusState private var focusedField: Field?
    #endif
    
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
        .frame(width: 340)
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
        .onExitCommand { dismiss() }
        #else
        NavigationStack {
            Form {
                serverConfigurationSection
                defaultSettingsSection
                advancedSection
                actionsSection
                
                if !statusMessage.isEmpty {
                    statusSection
                }
            }
            .formStyle(.grouped)
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
        #endif
    }
    
    // MARK: - Sections
    
    private var serverConfigurationSection: some View {
        #if os(macOS)
        VStack(alignment: .leading, spacing: 8) {
            Text("Server Configuration")
                .font(.headline)
            
            VStack(spacing: 8) {
                LabeledContent("Server URL") {
                    TextField("", text: $serverURL)
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)
                        .focused($focusedField, equals: .serverURL)
                        .onSubmit { focusedField = .username }
                }
                
                LabeledContent("Username") {
                    TextField("", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)
                        .focused($focusedField, equals: .username)
                        .onSubmit { focusedField = .password }
                }
                
                LabeledContent("Password") {
                    HStack {
                        if showPassword {
                            TextField("", text: $password)
                                .textFieldStyle(.roundedBorder)
                                .disableAutocorrection(true)
                                .focused($focusedField, equals: .password)
                                .onSubmit { focusedField = .createArchive }
                        } else {
                            SecureField("", text: $password)
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedField, equals: .password)
                                .onSubmit { focusedField = .createArchive }
                        }
                        
                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .focusable()
                        .focused($focusedField, equals: .showPassword)
                        .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                    }
                }
            }
            .macOSSectionStyle()
        }
        #else
        Section {
            TextField("Server URL", text: $serverURL)
                .textContentType(.URL)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .accessibilityHint("Enter your Shiori server URL, for example https://shiori.example.com")
            
            TextField("Username", text: $username)
                .textContentType(.username)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .accessibilityHint("Enter your Shiori username")
            
            HStack {
                if showPassword {
                    TextField("Password", text: $password)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } else {
                    SecureField("Password", text: $password)
                        .textContentType(.password)
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
        #endif
    }
    
    private var defaultSettingsSection: some View {
        #if os(macOS)
        VStack(alignment: .leading, spacing: 8) {
            Text("Default Settings")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Create Archive", isOn: $createArchive)
                    .focusable()
                    .focused($focusedField, equals: .createArchive)
                    .onKeyPress(.space) { createArchive.toggle(); return .handled }
                    .accessibilityHint("When enabled, Shiori will save an offline copy of the page")
                Toggle("Make Public", isOn: $makePublic)
                    .focusable()
                    .focused($focusedField, equals: .makePublic)
                    .onKeyPress(.space) { makePublic.toggle(); return .handled }
                    .accessibilityHint("When enabled, bookmarks will be publicly visible")
            }
            .macOSSectionStyle()
        }
        #else
        Section {
            Toggle("Create Archive", isOn: $createArchive)
                .accessibilityHint("When enabled, Shiori will save an offline copy of the page")
            Toggle("Make Public", isOn: $makePublic)
                .accessibilityHint("When enabled, bookmarks will be publicly visible")
        } header: {
            Text("Default Settings")
        }
        #endif
    }
    
    private var advancedSection: some View {
        #if os(macOS)
        VStack(alignment: .leading, spacing: 8) {
            Text("Advanced")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $trustSelfSignedCerts) {
                    HStack {
                        Text("Trust Self-Signed Certs")
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .accessibilityHidden(true)
                    }
                }
                .focusable()
                .focused($focusedField, equals: .trustSelfSignedCerts)
                .onKeyPress(.space) { trustSelfSignedCerts.toggle(); return .handled }
                .accessibilityHint("Enable this only for servers with self-signed certificates that you trust")
                
                if trustSelfSignedCerts {
                    Text("Only enable this for servers you trust.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Toggle("Enable Debug Logging", isOn: $debugLoggingEnabled)
                    .focusable()
                    .focused($focusedField, equals: .debugLogging)
                    .onKeyPress(.space) { debugLoggingEnabled.toggle(); return .handled }
                    .accessibilityHint("When enabled, saves detailed logs for troubleshooting")
            }
            .macOSSectionStyle()
        }
        #else
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
        #endif
    }
    
    private var actionsSection: some View {
        #if os(macOS)
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
        .buttonStyle(.bordered)
        .focusable()
        .focused($focusedField, equals: .testConnection)
        .onKeyPress(.space) {
            if !isTesting && isFormValid {
                testConnection()
                return .handled
            }
            return .ignored
        }
        .disabled(isTesting || !isFormValid)
        #else
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
        #endif
    }
    
    private var statusSection: some View {
        #if os(macOS)
        HStack {
            Image(systemName: isError ? "exclamationmark.triangle" : "checkmark.circle")
                .foregroundColor(isError ? .orange : .green)
            Text(statusMessage.isEmpty ? " " : statusMessage)
                .font(.callout)
        }
        .frame(minHeight: 20)
        #else
        Section {
            HStack {
                Image(systemName: isError ? "exclamationmark.triangle" : "checkmark.circle")
                    .foregroundColor(isError ? .orange : .green)
                Text(statusMessage)
                    .font(.callout)
            }
        }
        #endif
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
        serverURL = settings.serverURL ?? ""
        username = settings.username ?? ""
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
        
        settings.serverURL = normalizedURL
        settings.username = username
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

        Task {
            do {
                _ = try await ShioriAPI.shared.login(
                    serverURL: normalizedURL,
                    username: username,
                    password: password
                )

                await MainActor.run {
                    statusMessage = "Connection successful!"
                    isError = false
                    isTesting = false
                }
            } catch let error as ShioriAPIError {
                await MainActor.run {
                    statusMessage = error.errorDescription ?? "Unknown error"
                    isError = true
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    statusMessage = error.localizedDescription
                    isError = true
                    isTesting = false
                }
            }
        }
    }
    
}

#Preview {
    SettingsView()
}
