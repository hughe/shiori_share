#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import SwiftUI

#if os(iOS)
class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let hostingController = UIHostingController(rootView: ShareExtensionView(
            extensionContext: extensionContext,
            onCancel: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            },
            onComplete: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            }
        ))
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        hostingController.didMove(toParent: self)
    }
}
#elseif os(macOS)
class ShareViewController: NSViewController {
    override func loadView() {
        let hostingView = NSHostingView(rootView: ShareExtensionView(
            extensionContext: extensionContext,
            onCancel: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            },
            onComplete: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            }
        ))
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 500)
        self.view = hostingView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredContentSize = NSSize(width: 400, height: 500)
    }
}
#endif

// MARK: - View States

enum ShareViewState {
    case loading
    case form
    case saving
    case success(bookmarkId: Int)
    case error(ShioriAPIError)
    case notConfigured
    case noURL
}

// MARK: - Main View

struct ShareExtensionView: View {
    let extensionContext: NSExtensionContext?
    let onCancel: () -> Void
    let onComplete: () -> Void
    
    @State private var viewState: ShareViewState = .loading
    @State private var extractedURL: URL?
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var keywords: String = ""
    @State private var createArchive: Bool = true
    @State private var makePublic: Bool = false
    @State private var savedBookmarkId: Int?
    
    private let settings = SettingsManager.shared
    private let keychain = KeychainHelper.shared
    
    private var displayedTags: [String] {
        Array(settings.recentTags.prefix(AppConstants.Defaults.displayedTagChips))
    }
    
    private var tagSuggestions: [String] {
        guard let lastTag = keywords.components(separatedBy: ",").last?.trimmingCharacters(in: .whitespaces).lowercased(),
              !lastTag.isEmpty else {
            return []
        }
        return settings.recentTags.filter { $0.lowercased().hasPrefix(lastTag) && !keywords.lowercased().contains($0.lowercased()) }
    }
    
    var body: some View {
        #if os(macOS)
        VStack(spacing: 0) {
            HStack {
                Text("Save to Shiori")
                    .font(.headline)
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
            }
            .padding()
            
            Divider()
            
            Group {
                switch viewState {
                case .loading:
                    loadingView
                case .form:
                    formView
                case .saving:
                    savingView
                case .success(let bookmarkId):
                    successView(bookmarkId: bookmarkId)
                case .error(let error):
                    errorView(error: error)
                case .notConfigured:
                    notConfiguredView
                case .noURL:
                    noURLView
                }
            }
        }
        .frame(minWidth: 380, minHeight: 400)
        .task {
            await loadContent()
        }
        #else
        NavigationStack {
            Group {
                switch viewState {
                case .loading:
                    loadingView
                case .form:
                    formView
                case .saving:
                    savingView
                case .success(let bookmarkId):
                    successView(bookmarkId: bookmarkId)
                case .error(let error):
                    errorView(error: error)
                case .notConfigured:
                    notConfiguredView
                case .noURL:
                    noURLView
                }
            }
            .navigationTitle("Save to Shiori")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
        .task {
            await loadContent()
        }
        #endif
    }
    
    // MARK: - Views
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading...")
                .foregroundColor(.secondary)
        }
    }
    
    private var formView: some View {
        #if os(macOS)
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // URL Section
                VStack(alignment: .leading, spacing: 4) {
                    Text("URL")
                        .font(.headline)
                    if let url = extractedURL {
                        Text(url.absoluteString)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .textSelection(.enabled)
                    }
                }
                
                Divider()
                
                // Details Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Details")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Title", text: $title)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("Description")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextEditor(text: $description)
                            .frame(height: 60)
                            .border(Color.secondary.opacity(0.3), width: 1)
                        
                        TextField("Tags (comma-separated)", text: $keywords)
                            .textFieldStyle(.roundedBorder)
                        
                        if !tagSuggestions.isEmpty {
                            FlowLayout(spacing: 6) {
                                ForEach(tagSuggestions.prefix(5), id: \.self) { tag in
                                    Button(tag) { completeTag(tag) }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                }
                            }
                        } else if !displayedTags.isEmpty {
                            FlowLayout(spacing: 6) {
                                ForEach(displayedTags, id: \.self) { tag in
                                    Button(tag) { addTag(tag) }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                // Options
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Create Archive", isOn: $createArchive)
                    Toggle("Make Public", isOn: $makePublic)
                }
                
                Divider()
                
                // Save Button
                HStack {
                    Spacer()
                    Button {
                        Task { await saveBookmark() }
                    } label: {
                        Text("Save Bookmark")
                            .frame(minWidth: 120)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding()
        }
        #else
        Form {
            Section {
                if let url = extractedURL {
                    Text(url.absoluteString)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .accessibilityLabel("URL to save: \(url.absoluteString)")
                }
            } header: {
                Text("URL")
            }
            
            Section {
                TextField("Title", text: $title)
                    .accessibilityHint("Optional title for the bookmark")
                
                TextEditor(text: $description)
                    .frame(minHeight: 60, maxHeight: 100)
                    .accessibilityLabel("Description")
                    .accessibilityHint("Optional description or notes for the bookmark")
                
                TextField("Keywords (comma-separated)", text: $keywords)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityHint("Enter tags separated by commas")
                
                if !tagSuggestions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(tagSuggestions.prefix(5), id: \.self) { tag in
                                Button(tag) {
                                    completeTag(tag)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .accessibilityLabel("Complete with \(tag)")
                            }
                        }
                    }
                    .accessibilityLabel("Tag suggestions")
                } else if !displayedTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(displayedTags, id: \.self) { tag in
                                Button(tag) {
                                    addTag(tag)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .accessibilityLabel("Add tag \(tag)")
                            }
                        }
                    }
                    .accessibilityLabel("Popular tags")
                }
            } header: {
                Text("Details")
            }
            
            Section {
                Toggle("Create Archive", isOn: $createArchive)
                    .accessibilityHint("When enabled, Shiori saves an offline copy of the page")
                Toggle("Make Public", isOn: $makePublic)
                    .accessibilityHint("When enabled, this bookmark will be publicly visible")
            }
            
            Section {
                Button {
                    Task {
                        await saveBookmark()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("Save Bookmark")
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
            }
        }
        .formStyle(.grouped)
        #endif
    }
    
    private var savingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                #if os(macOS)
                .scaleEffect(1.5)
                #endif
                .accessibilityHidden(true)
            Text("Saving bookmark...")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Saving bookmark, please wait")
    }
    
    private func successView(bookmarkId: Int) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(.green)
                .accessibilityHidden(true)
            
            Text("Bookmark saved!")
                .font(.title2)
            
            Button("Done") {
                onComplete()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .onAppear {
            #if os(iOS)
            playHapticFeedback(type: .success)
            UIAccessibility.post(notification: .announcement, argument: "Bookmark saved successfully")
            #endif
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Timing.successAutoCloseDelay) {
                onComplete()
            }
        }
    }
    
    private func errorView(error: ShioriAPIError) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundColor(.orange)
                .accessibilityHidden(true)
            
            Text(error.localizedDescription)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                
                if error.isRetryable {
                    Button("Retry") {
                        Task {
                            await saveBookmark()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .onAppear {
            #if os(iOS)
            playHapticFeedback(type: .error)
            UIAccessibility.post(notification: .announcement, argument: "Error: \(error.localizedDescription)")
            #endif
        }
    }
    
    private var notConfiguredView: some View {
        VStack(spacing: 20) {
            Image(systemName: "gearshape.circle")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            
            Text("Server Not Configured")
                .font(.title2)
            
            Text("Please open the Shiori Share app to configure your server credentials.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("OK", action: onCancel)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var noURLView: some View {
        VStack(spacing: 20) {
            Image(systemName: "link.badge.plus")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            
            Text("No URL Found")
                .font(.title2)
            
            Text("The shared content doesn't contain a URL. Try sharing from a browser or app that shares links.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("OK", action: onCancel)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Actions
    
    private func loadContent() async {
        guard keychain.hasCredentials else {
            viewState = .notConfigured
            return
        }
        
        createArchive = settings.defaultCreateArchive
        makePublic = settings.defaultMakePublic
        
        // Refresh popular tags from server in background
        Task {
            await ShioriAPI.shared.refreshPopularTags()
        }
        
        do {
            let content = try await URLExtractor.extract(from: extensionContext)
            extractedURL = content.url
            title = content.title ?? ""
            viewState = .form
        } catch {
            DebugLogger.shared.error(error, context: "URL extraction failed")
            viewState = .noURL
        }
    }
    
    private func saveBookmark() async {
        guard let url = extractedURL else {
            viewState = .noURL
            return
        }
        
        viewState = .saving
        
        do {
            #if os(iOS)
            let response = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<BookmarkResponse, Error>) in
                ProcessInfo.processInfo.performExpiringActivity(withReason: "Saving bookmark to Shiori") { expired in
                    if expired {
                        continuation.resume(throwing: ShioriAPIError.connectionFailed(NSError(domain: "ShioriShare", code: -1, userInfo: [NSLocalizedDescriptionKey: "Operation expired"])))
                        return
                    }
                    
                    Task {
                        do {
                            let result = try await ShioriAPI.shared.addBookmark(
                                url: url.absoluteString,
                                title: self.title.isEmpty ? nil : self.title,
                                description: self.description.isEmpty ? nil : self.description,
                                keywords: self.keywords.isEmpty ? nil : self.keywords,
                                createArchive: self.createArchive,
                                makePublic: self.makePublic
                            )
                            continuation.resume(returning: result)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
            #else
            let response = try await ShioriAPI.shared.addBookmark(
                url: url.absoluteString,
                title: self.title.isEmpty ? nil : self.title,
                description: self.description.isEmpty ? nil : self.description,
                keywords: self.keywords.isEmpty ? nil : self.keywords,
                createArchive: self.createArchive,
                makePublic: self.makePublic
            )
            #endif
            
            viewState = .success(bookmarkId: response.id)
        } catch let error as ShioriAPIError {
            viewState = .error(error)
        } catch {
            viewState = .error(.unknownError(error))
        }
    }
    
    private func addTag(_ tag: String) {
        if keywords.isEmpty {
            keywords = tag
        } else if !keywords.contains(tag) {
            keywords += ", \(tag)"
        }
    }
    
    private func completeTag(_ tag: String) {
        var parts = keywords.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        if !parts.isEmpty {
            parts[parts.count - 1] = tag
        } else {
            parts = [tag]
        }
        keywords = parts.joined(separator: ", ") + ", "
    }
    
    #if os(iOS)
    private func playHapticFeedback(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    #endif
}
