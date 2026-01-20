import Foundation

extension String {
    var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return url.scheme != nil && url.host != nil
    }
    
    var isValidHTTPURL: Bool {
        guard let url = URL(string: self),
              let scheme = url.scheme?.lowercased() else {
            return false
        }
        return (scheme == "http" || scheme == "https") && url.host != nil
    }
    
    var normalizedServerURL: String {
        var result = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !result.lowercased().hasPrefix("http://") && !result.lowercased().hasPrefix("https://") {
            result = "https://\(result)"
        }
        
        while result.hasSuffix("/") {
            result.removeLast()
        }
        
        return result
    }
    
    var extractedURL: URL? {
        if let url = URL(string: self), url.scheme != nil, url.host != nil {
            return url
        }
        
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(startIndex..., in: self)
        
        if let match = detector?.firstMatch(in: self, options: [], range: range),
           let url = match.url {
            return url
        }
        
        return nil
    }
}

extension URL {
    var isHTTP: Bool {
        guard let scheme = scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }
    
    func appendingPathSafely(_ path: String) -> URL {
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return appendingPathComponent(cleanPath)
    }
}
