import SwiftUI

struct InstructionsView: View {
    #if os(iOS)
    @State private var isTesting = false
    @State private var testResult: TestResult?
    @State private var showPasswordPrompt = false
    @State private var testPassword = ""
    
    private let settings = SettingsManager.shared
    private let keychain = KeychainHelper.shared
    
    enum TestResult {
        case success
        case error(String)
    }
    #endif
    
    var body: some View {
        #if os(macOS)
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                Divider()
                configureSection
                Divider()
                howToUseSection
                Divider()
                tipSection
            }
            .padding()
        }
        .frame(minWidth: 270, minHeight: 300)
        #else
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    Divider()
                    setupSection
                    Divider()
                    howToUseSection
                    Divider()
                    tipSection
                    Divider()
                    aboutSection
                }
                .padding()
            }
            .navigationTitle("Shiori Share")
        }
        #endif
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Shiori Share", systemImage: "books.vertical")
                .font(.title2.weight(.semibold))
            
            Text("Save bookmarks from Safari to your Shiori server")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    #if os(macOS)
    private var configureSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Configure", systemImage: "gearshape")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Open Settings from the menu bar (⌘,) to configure your Shiori server URL and username.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
    #endif
    
    #if os(iOS)
    private var setupSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Setup", systemImage: "gearshape")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Configure your Shiori server in the Settings app:")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Open Settings", systemImage: "arrow.up.forward.app")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button {
                        testConnection()
                    } label: {
                        if isTesting {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Label("Test Connection", systemImage: "network")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isTesting || settings.serverURL == nil || settings.username == nil)
                }
                
                if let result = testResult {
                    HStack {
                        switch result {
                        case .success:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Connection successful!")
                        case .error(let message):
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(message)
                        }
                    }
                    .font(.callout)
                }
            }
        }
        .alert("Enter Password", isPresented: $showPasswordPrompt) {
            SecureField("Password", text: $testPassword)
            Button("Cancel", role: .cancel) {
                testPassword = ""
            }
            Button("Test") {
                testConnectionWithPassword(testPassword)
            }
        } message: {
            Text("Enter your Shiori password to test the connection.")
        }
    }
    
    private func testConnection() {
        if let savedPassword = keychain.password {
            testConnectionWithPassword(savedPassword)
        } else {
            showPasswordPrompt = true
        }
    }
    
    private func testConnectionWithPassword(_ password: String) {
        guard let serverURL = settings.serverURL,
              let username = settings.username else {
            testResult = .error("Server not configured")
            return
        }
        
        isTesting = true
        testResult = nil
        testPassword = ""
        
        Task {
            do {
                _ = try await ShioriAPI.shared.login(
                    serverURL: serverURL,
                    username: username,
                    password: password
                )
                
                keychain.password = password
                
                await MainActor.run {
                    testResult = .success
                    isTesting = false
                }
            } catch let error as ShioriAPIError {
                await MainActor.run {
                    testResult = .error(error.localizedDescription)
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    testResult = .error(error.localizedDescription)
                    isTesting = false
                }
            }
        }
    }
    #endif
    
    private var howToUseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("How to Use", systemImage: "square.and.arrow.up")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                #if os(macOS)
                instructionStep(number: 1, text: "In Safari (or any browser), click the share button on any page")
                instructionStep(number: 2, text: "Select \"Shiori Share\" from the share menu")
                instructionStep(number: 3, text: "Enter your password if prompted (first time only)")
                instructionStep(number: 4, text: "Add tags and a description if desired")
                instructionStep(number: 5, text: "Click Save to bookmark the page")
                #else
                instructionStep(number: 1, text: "In Safari (or any browser), tap the share button on any page")
                instructionStep(number: 2, text: "Select \"Shiori Share\" from the share sheet")
                instructionStep(number: 3, text: "Enter your password if prompted (first time only)")
                instructionStep(number: 4, text: "Add tags and a description if desired")
                instructionStep(number: 5, text: "Tap Save to bookmark the page")
                #endif
            }
        }
    }
    
    private func instructionStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.accentColor)
                .clipShape(Circle())
            
            Text(text)
                .font(.body)
        }
    }
    
    private var tipSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tip", systemImage: "lightbulb")
                .font(.headline)
            
            Text("To move Shiori Share higher in the share sheet, scroll right and tap \"More\", then tap \"Edit\" to reorder.")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("About Shiori", systemImage: "info.circle")
                .font(.headline)
            
            Text("Shiori is a simple, self-hosted, bookmark manager built with Go.")
                .font(.body)
                .foregroundColor(.secondary)
            
            Link(destination: URL(string: "https://github.com/go-shiori/shiori")!) {
                Label("github.com/go-shiori/shiori", systemImage: "link")
                    .font(.body)
            }
        }
    }
}

#Preview {
    InstructionsView()
}
