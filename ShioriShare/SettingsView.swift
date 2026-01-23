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
    @State private var showPasswordPrompt: Bool = false
    @State private var promptedPassword: String = ""
    private enum Field: Int, CaseIterable {
        case serverURL, username
        case createArchive, makePublic
        case trustSelfSignedCerts, debugLogging
        case testConnection
    }
    @FocusState private var focusedField: Field?
    
    private let keychain = KeychainHelper.shared
    private let settings = SettingsManager.shared
    
    var body: some View {
        Form {
            Section("Server Configuration") {
                TextField("Server URL", text: $serverURL)
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: .serverURL)
                    .onSubmit { focusedField = .username }
                    .onChange(of: serverURL) { _, newValue in
                        settings.serverURL = newValue.normalizedServerURL
                    }
                
                TextField("Username", text: $username)
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: .username)
                    .onChange(of: username) { _, newValue in
                        settings.username = newValue
                    }
            }
            
            Section("Default Settings") {
                Toggle("Create Archive", isOn: $createArchive)
                    .onChange(of: createArchive) { _, newValue in
                        settings.defaultCreateArchive = newValue
                    }
                Toggle("Make Public", isOn: $makePublic)
                    .onChange(of: makePublic) { _, newValue in
                        settings.defaultMakePublic = newValue
                    }
            }
            
            Section("Advanced") {
                Toggle(isOn: $trustSelfSignedCerts) {
                    HStack {
                        Text("Trust Self-Signed Certs")
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                    }
                }
                .onChange(of: trustSelfSignedCerts) { _, newValue in
                    settings.trustSelfSignedCerts = newValue
                }
                
                Toggle("Enable Debug Logging", isOn: $debugLoggingEnabled)
                    .onChange(of: debugLoggingEnabled) { _, newValue in
                        settings.debugLoggingEnabled = newValue
                    }
            }
            
            Section("Password") {
                if keychain.password != nil {
                    HStack {
                        Text("Password saved in Keychain")
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Clear") {
                            keychain.clearPassword()
                            settings.clearSession()
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    Text("Password will be prompted on first use")
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                HStack {
                    Button {
                        testConnection()
                    } label: {
                        if isTesting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Test Connection")
                        }
                    }
                    .disabled(isTesting || !isFormValid)
                    
                    if !statusMessage.isEmpty {
                        Image(systemName: isError ? "exclamationmark.triangle" : "checkmark.circle")
                            .foregroundColor(isError ? .orange : .green)
                        Text(statusMessage)
                            .font(.callout)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .onAppear(perform: loadSettings)
        .sheet(isPresented: $showPasswordPrompt) {
            VStack(spacing: 20) {
                Text("Enter Password")
                    .font(.headline)
                
                Text("Enter your Shiori password to test the connection.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                SecureField("Password", text: $promptedPassword)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 250)
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        showPasswordPrompt = false
                        promptedPassword = ""
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Test") {
                        showPasswordPrompt = false
                        testConnectionWithPassword(promptedPassword)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(promptedPassword.isEmpty)
                }
            }
            .padding(40)
            .frame(width: 350)
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !serverURL.trimmingCharacters(in: .whitespaces).isEmpty &&
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        serverURL.normalizedServerURL.isValidHTTPURL
    }
    
    // MARK: - Actions
    
    private func loadSettings() {
        serverURL = settings.serverURL ?? ""
        username = settings.username ?? ""
        
        createArchive = settings.defaultCreateArchive
        makePublic = settings.defaultMakePublic
        trustSelfSignedCerts = settings.trustSelfSignedCerts
        debugLoggingEnabled = settings.debugLoggingEnabled
    }
    
    private func testConnection() {
        if let savedPassword = keychain.password {
            testConnectionWithPassword(savedPassword)
        } else {
            showPasswordPrompt = true
        }
    }
    
    private func testConnectionWithPassword(_ testPassword: String) {
        isTesting = true
        statusMessage = ""
        
        let normalizedURL = serverURL.normalizedServerURL
        
        Task {
            do {
                _ = try await ShioriAPI.shared.login(
                    serverURL: normalizedURL,
                    username: username,
                    password: testPassword
                )
                
                keychain.password = testPassword
                promptedPassword = ""
                
                await MainActor.run {
                    statusMessage = "Connection successful! Password saved."
                    isError = false
                    isTesting = false
                }
            } catch let error as ShioriAPIError {
                await MainActor.run {
                    statusMessage = error.errorDescription ?? "Unknown error"
                    isError = true
                    isTesting = false
                    promptedPassword = ""
                }
            } catch {
                await MainActor.run {
                    statusMessage = error.localizedDescription
                    isError = true
                    isTesting = false
                    promptedPassword = ""
                }
            }
        }
    }
    
}

#Preview {
    SettingsView()
}

#endif
