import UIKit
import SwiftUI

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
    
    var body: some View {
        NavigationView {
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
        .navigationViewStyle(.stack)
        .task {
            await loadContent()
        }
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
        Form {
            Section {
                if let url = extractedURL {
                    Text(url.absoluteString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            } header: {
                Text("URL")
            }
            
            Section {
                TextField("Title", text: $title)
                
                TextEditor(text: $description)
                    .frame(minHeight: 60, maxHeight: 100)
                
                TextField("Keywords (comma-separated)", text: $keywords)
                
                if !settings.recentTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(settings.recentTags, id: \.self) { tag in
                                Button(tag) {
                                    addTag(tag)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                }
            } header: {
                Text("Details")
            }
            
            Section {
                Toggle("Create Archive", isOn: $createArchive)
                Toggle("Make Public", isOn: $makePublic)
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
    }
    
    private var savingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Saving bookmark...")
                .foregroundColor(.secondary)
        }
    }
    
    private func successView(bookmarkId: Int) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Bookmark saved!")
                .font(.headline)
            
            Button("Done") {
                onComplete()
            }
            .buttonStyle(.borderedProminent)
        }
        .onAppear {
            playHapticFeedback(type: .success)
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Timing.successAutoCloseDelay) {
                onComplete()
            }
        }
    }
    
    private func errorView(error: ShioriAPIError) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text(error.localizedDescription ?? "An error occurred")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)
                
                if error.isRetryable {
                    Button("Retry") {
                        Task {
                            await saveBookmark()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .onAppear {
            playHapticFeedback(type: .error)
        }
    }
    
    private var notConfiguredView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Server Not Configured")
                .font(.headline)
            
            Text("Please open the Shiori Share app to configure your server credentials.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("OK", action: onCancel)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var noURLView: some View {
        VStack(spacing: 20) {
            Image(systemName: "link.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("No URL Found")
                .font(.headline)
            
            Text("The shared content doesn't contain a URL. Try sharing from a browser or app that shares links.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("OK", action: onCancel)
                .buttonStyle(.borderedProminent)
        }
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
    
    private func playHapticFeedback(type: UINotificationFeedbackGenerator.FeedbackType) {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
        #endif
    }
}
