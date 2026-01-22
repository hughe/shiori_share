import Foundation
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct ExtractedContent {
    let url: URL
    let title: String?
}

final class URLExtractor {
    
    enum ExtractionError: LocalizedError {
        case noURLFound
        case invalidContent
        case extractionFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .noURLFound:
                return "No URL found in shared content"
            case .invalidContent:
                return "The shared content is not valid"
            case .extractionFailed(let error):
                return "Failed to extract URL: \(error.localizedDescription)"
            }
        }
    }
    
    #if canImport(UIKit)
    @MainActor
    static func extract(from extensionContext: NSExtensionContext?) async throws -> ExtractedContent {
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            throw ExtractionError.invalidContent
        }
        
        for item in inputItems {
            guard let attachments = item.attachments else { continue }
            
            if let result = try? await extractFromURL(attachments: attachments, item: item) {
                return result
            }
            
            if let result = try? await extractFromText(attachments: attachments, item: item) {
                return result
            }
        }
        
        throw ExtractionError.noURLFound
    }
    
    @MainActor
    private static func extractFromURL(attachments: [NSItemProvider], item: NSExtensionItem) async throws -> ExtractedContent {
        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                let url = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if let url = item as? URL {
                            continuation.resume(returning: url)
                        } else if let urlData = item as? Data, let url = URL(dataRepresentation: urlData, relativeTo: nil) {
                            continuation.resume(returning: url)
                        } else {
                            continuation.resume(throwing: ExtractionError.invalidContent)
                        }
                    }
                }
                
                let title = item.attributedContentText?.string ?? extractTitle(from: item)
                return ExtractedContent(url: url, title: title)
            }
        }
        throw ExtractionError.noURLFound
    }
    
    @MainActor
    private static func extractFromText(attachments: [NSItemProvider], item: NSExtensionItem) async throws -> ExtractedContent {
        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                let text = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if let text = item as? String {
                            continuation.resume(returning: text)
                        } else {
                            continuation.resume(throwing: ExtractionError.invalidContent)
                        }
                    }
                }
                
                guard let url = text.extractedURL else {
                    throw ExtractionError.noURLFound
                }
                
                let title = item.attributedContentText?.string ?? extractTitle(from: item)
                return ExtractedContent(url: url, title: title)
            }
        }
        throw ExtractionError.noURLFound
    }
    
    private static func extractTitle(from item: NSExtensionItem) -> String? {
        if let title = item.attributedTitle?.string, !title.isEmpty {
            return title
        }
        if let text = item.attributedContentText?.string, !text.isEmpty, text.count < 200 {
            if text.extractedURL == nil {
                return text
            }
        }
        return nil
    }
    #endif
    
    #if canImport(AppKit) && !canImport(UIKit)
    @MainActor
    static func extract(from extensionContext: NSExtensionContext?) async throws -> ExtractedContent {
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            throw ExtractionError.invalidContent
        }
        
        for item in inputItems {
            guard let attachments = item.attachments else { continue }
            
            if let result = try? await extractFromURL(attachments: attachments, item: item) {
                return result
            }
            
            if let result = try? await extractFromText(attachments: attachments, item: item) {
                return result
            }
        }
        
        throw ExtractionError.noURLFound
    }
    
    @MainActor
    private static func extractFromURL(attachments: [NSItemProvider], item: NSExtensionItem) async throws -> ExtractedContent {
        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                let url = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if let url = item as? URL {
                            continuation.resume(returning: url)
                        } else if let urlData = item as? Data, let url = URL(dataRepresentation: urlData, relativeTo: nil) {
                            continuation.resume(returning: url)
                        } else {
                            continuation.resume(throwing: ExtractionError.invalidContent)
                        }
                    }
                }
                
                let title = item.attributedContentText?.string ?? extractTitle(from: item)
                return ExtractedContent(url: url, title: title)
            }
        }
        throw ExtractionError.noURLFound
    }
    
    @MainActor
    private static func extractFromText(attachments: [NSItemProvider], item: NSExtensionItem) async throws -> ExtractedContent {
        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                let text = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if let text = item as? String {
                            continuation.resume(returning: text)
                        } else {
                            continuation.resume(throwing: ExtractionError.invalidContent)
                        }
                    }
                }
                
                guard let url = text.extractedURL else {
                    throw ExtractionError.noURLFound
                }
                
                let title = item.attributedContentText?.string ?? extractTitle(from: item)
                return ExtractedContent(url: url, title: title)
            }
        }
        throw ExtractionError.noURLFound
    }
    
    private static func extractTitle(from item: NSExtensionItem) -> String? {
        if let title = item.attributedTitle?.string, !title.isEmpty {
            return title
        }
        if let text = item.attributedContentText?.string, !text.isEmpty, text.count < 200 {
            if text.extractedURL == nil {
                return text
            }
        }
        return nil
    }
    #endif
}
